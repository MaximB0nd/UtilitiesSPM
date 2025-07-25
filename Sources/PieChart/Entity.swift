//
//  File.swift
//  Utilities
//
//  Created by Максим Бондарев on 25.07.2025.
//

import Foundation

public struct Entity {
    public let value: Decimal
    public let label: String
    public init(value: Decimal, label: String) {
        self.value = value
        self.label = label
    }
}
