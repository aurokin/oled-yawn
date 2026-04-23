import CoreFoundation
import CoreGraphics
import Foundation
import IOKit
import OLEDYawnCore

@_silgen_name("CoreDisplay_DisplayCreateInfoDictionary")
func CoreDisplay_DisplayCreateInfoDictionary(_ display: CGDirectDisplayID) -> Unmanaged<CFDictionary>?

@_silgen_name("IOAVServiceCreateWithService")
func IOAVServiceCreateWithService(_ allocator: CFAllocator?, _ service: io_service_t) -> Unmanaged<AnyObject>?

@_silgen_name("IOAVServiceWriteI2C")
func IOAVServiceWriteI2C(
    _ service: AnyObject,
    _ chipAddress: UInt32,
    _ offset: UInt32,
    _ inputBuffer: UnsafeMutableRawPointer,
    _ inputBufferSize: UInt32
) -> IOReturn

struct HardwareDisplay {
    let id: CGDirectDisplayID
    let summary: DisplaySummary
    let ioLocation: String
}

struct AVServiceResolution {
    let service: AnyObject
    let strategy: String
}

enum Hardware {
    static func listDisplays() -> [HardwareDisplay] {
        let maxDisplays: UInt32 = 16
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        var count: UInt32 = 0

        guard CGGetOnlineDisplayList(maxDisplays, &ids, &count) == .success else {
            return []
        }

        var result: [HardwareDisplay] = []
        for id in ids.prefix(Int(count)) {
            guard let infoRef = CoreDisplay_DisplayCreateInfoDictionary(id) else {
                continue
            }

            let info = infoRef.takeRetainedValue() as NSDictionary
            guard let uuid = info["kCGDisplayUUID"] as? String,
                let ioLocation = info["IODisplayLocation"] as? String
            else {
                continue
            }

            let productName = productName(for: ioLocation)
            let summary = DisplaySummary(index: result.count + 1, uuid: uuid, productName: productName)
            result.append(HardwareDisplay(id: id, summary: summary, ioLocation: ioLocation))
        }

        return result
    }

    static func avService(for display: HardwareDisplay) -> AnyObject? {
        resolveAVService(for: display)?.service
    }

    static func resolveAVService(for display: HardwareDisplay) -> AVServiceResolution? {
        let rootService = IORegistryEntryCopyFromPath(kIOMainPortDefault, display.ioLocation as CFString)
        if rootService != MACH_PORT_NULL {
            defer { IOObjectRelease(rootService) }
            if let av = firstExternalAVService(startingAt: rootService) {
                return AVServiceResolution(service: av, strategy: "display subtree")
            }
        }

        guard let av = firstExternalAVService(afterRegistryPath: display.ioLocation) else {
            return nil
        }

        return AVServiceResolution(service: av, strategy: "registry-order fallback")
    }

    static func externalAVServiceProxyCount() -> Int {
        countRegistryEntries(named: "DCPAVServiceProxy", location: "External")
    }

    @discardableResult
    static func ddcWrite(_ av: AnyObject, vcp: UInt8, value: UInt16) -> IOReturn {
        let inputAddress: UInt8 = 0x51
        var data = [UInt8](repeating: 0, count: 6)
        data[0] = 0x84
        data[1] = 0x03
        data[2] = vcp
        data[3] = UInt8((value >> 8) & 0xFF)
        data[4] = UInt8(value & 0xFF)
        data[5] = 0x6E ^ inputAddress ^ data[0] ^ data[1] ^ data[2] ^ data[3] ^ data[4]

        var ret: IOReturn = KERN_SUCCESS
        for _ in 0..<2 {
            usleep(10_000)
            ret = data.withUnsafeMutableBufferPointer { buffer in
                IOAVServiceWriteI2C(
                    av,
                    0x37,
                    UInt32(inputAddress),
                    UnsafeMutableRawPointer(buffer.baseAddress!),
                    UInt32(buffer.count)
                )
            }
            if ret != KERN_SUCCESS {
                return ret
            }
        }

        return ret
    }

    private static func productName(for ioLocation: String) -> String {
        let adapter = IORegistryEntryCopyFromPath(kIOMainPortDefault, ioLocation as CFString)
        guard adapter != MACH_PORT_NULL else {
            return "Unknown Display"
        }
        defer { IOObjectRelease(adapter) }

        let attrs =
            IORegistryEntrySearchCFProperty(
                adapter,
                kIOServicePlane,
                "DisplayAttributes" as CFString,
                kCFAllocatorDefault,
                IOOptionBits(kIORegistryIterateRecursively)
            ) as? [String: Any]

        if let product = attrs?["ProductAttributes"] as? [String: Any],
            let name = product["ProductName"] as? String
        {
            return name
        }

        return "Unknown Display"
    }

    private static func firstExternalAVService(startingAt rootService: io_service_t) -> AnyObject? {
        var iterator: io_iterator_t = 0
        guard
            IORegistryEntryCreateIterator(
                rootService,
                kIOServicePlane,
                IOOptionBits(kIORegistryIterateRecursively),
                &iterator
            ) == KERN_SUCCESS
        else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        while true {
            let service = IOIteratorNext(iterator)
            if service == MACH_PORT_NULL {
                break
            }

            defer { IOObjectRelease(service) }
            guard registryEntryName(service) == "DCPAVServiceProxy",
                registryStringProperty(service, "Location") == "External",
                let unmanaged = IOAVServiceCreateWithService(kCFAllocatorDefault, service)
            else {
                continue
            }

            return unmanaged.takeRetainedValue()
        }

        return nil
    }

    private static func firstExternalAVService(afterRegistryPath targetPath: String) -> AnyObject? {
        let root = IORegistryGetRootEntry(kIOMainPortDefault)
        var iterator: io_iterator_t = 0
        guard
            IORegistryEntryCreateIterator(
                root,
                kIOServicePlane,
                IOOptionBits(kIORegistryIterateRecursively),
                &iterator
            ) == KERN_SUCCESS
        else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        var hasSeenDisplay = false
        while true {
            let service = IOIteratorNext(iterator)
            if service == MACH_PORT_NULL {
                break
            }

            if !hasSeenDisplay {
                hasSeenDisplay = registryPath(service) == targetPath
                IOObjectRelease(service)
                continue
            }

            guard registryEntryName(service) == "DCPAVServiceProxy",
                registryStringProperty(service, "Location") == "External",
                let unmanaged = IOAVServiceCreateWithService(kCFAllocatorDefault, service)
            else {
                IOObjectRelease(service)
                continue
            }

            IOObjectRelease(service)
            return unmanaged.takeRetainedValue()
        }

        return nil
    }

    private static func countRegistryEntries(named targetName: String, location: String) -> Int {
        let root = IORegistryGetRootEntry(kIOMainPortDefault)
        var iterator: io_iterator_t = 0
        guard
            IORegistryEntryCreateIterator(
                root,
                kIOServicePlane,
                IOOptionBits(kIORegistryIterateRecursively),
                &iterator
            ) == KERN_SUCCESS
        else {
            return 0
        }
        defer { IOObjectRelease(iterator) }

        var count = 0
        while true {
            let service = IOIteratorNext(iterator)
            if service == MACH_PORT_NULL {
                break
            }

            if registryEntryName(service) == targetName,
                registryStringProperty(service, "Location") == location
            {
                count += 1
            }
            IOObjectRelease(service)
        }

        return count
    }

    private static func registryEntryName(_ service: io_service_t) -> String? {
        var buffer = [CChar](repeating: 0, count: 128)
        guard IORegistryEntryGetName(service, &buffer) == KERN_SUCCESS else {
            return nil
        }

        let nameBytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: nameBytes, as: UTF8.self)
    }

    private static func registryPath(_ service: io_service_t) -> String? {
        var buffer = [CChar](repeating: 0, count: 512)
        guard IORegistryEntryGetPath(service, kIOServicePlane, &buffer) == KERN_SUCCESS else {
            return nil
        }

        let pathBytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: pathBytes, as: UTF8.self)
    }

    private static func registryStringProperty(_ service: io_service_t, _ key: String) -> String? {
        IORegistryEntrySearchCFProperty(
            service,
            kIOServicePlane,
            key as CFString,
            kCFAllocatorDefault,
            IOOptionBits(kIORegistryIterateRecursively)
        ) as? String
    }
}
