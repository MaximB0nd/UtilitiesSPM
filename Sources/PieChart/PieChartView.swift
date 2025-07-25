//
//  File.swift
//  Utilities
//
//  Created by Максим Бондарев on 25.07.2025.
//

import Foundation
import UIKit

public final class PieChartView: UIView {
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var entities: [Entity] = [] {
        didSet {
            animateChartChange(from: oldValue, to: entities)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    private var animationProgress: CGFloat = 1.0
    private var isAnimatingChange = false
    private var oldEntities: [Entity] = []
    
    private func animateChartChange(from old: [Entity], to new: [Entity]) {
        guard !isAnimatingChange else { return }
        isAnimatingChange = true
        oldEntities = old
        animationProgress = 0.0
        let displayLink = CADisplayLink(target: self, selector: #selector(handleAnimationStep))
        displayLink.add(to: .main, forMode: .default)
    }

    @objc private func handleAnimationStep(displayLink: CADisplayLink) {
        animationProgress += CGFloat(displayLink.duration) * 2
        if animationProgress >= 1.0 {
            animationProgress = 1.0
            isAnimatingChange = false
            displayLink.invalidate()
        }
        setNeedsDisplay()
    }
    
    private let colors: [UIColor] = [
        .systemBlue,
        .systemGreen,
        .systemOrange,
        .systemPurple,
        .systemYellow,
        .systemGray
    ]
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if isAnimatingChange {
            let progress = animationProgress
            let angle: CGFloat
            let alpha: CGFloat
            let entitiesToDraw: [Entity]
            if progress < 0.5 {
                angle = .pi * 2 * progress
                alpha = 1.0 - progress * 2
                entitiesToDraw = prepareEntities(oldEntities)
            } else {
                angle = .pi * 2 * progress
                alpha = (progress - 0.5) * 2
                entitiesToDraw = prepareEntities(entities)
            }
            context.saveGState()
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: angle)
            context.translateBy(x: -center.x, y: -center.y)
            context.setAlpha(alpha)
            drawPieChart(context: context, entities: entitiesToDraw)
            context.restoreGState()
        } else {
            drawPieChart(context: context, entities: prepareEntities(entities))
        }
    }

    private func drawPieChart(context: CGContext, entities: [Entity]) {
        guard !entities.isEmpty else { return }
        let totalValue = entities.reduce(0) { $0 + $1.value }
        guard totalValue > 0 else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) * 0.4
        var startAngle: CGFloat = -.pi / 2
        for (index, entity) in entities.enumerated() {
            let percentage = CGFloat((entity.value as NSDecimalNumber).doubleValue / CGFloat((totalValue as NSDecimalNumber).doubleValue))
            let endAngle = startAngle + 2 * .pi * percentage
            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(
                withCenter: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )
            path.close()
            colors[index % colors.count].setFill()
            path.fill()
            drawLegend(
                context: context,
                entity: entity,
                percentage: percentage,
                center: center,
                midAngle: (startAngle + endAngle) / 2,
                radius: radius * 0.6
            )
            startAngle = endAngle
        }
    }
    
    private func prepareEntities(_ entities: [Entity]) -> [Entity] {
        guard entities.count > 5 else { return entities }
        
        let firstFive = Array(entities.prefix(5))
        let others = entities.dropFirst(5)
        let othersValue = others.reduce(0) { $0 + $1.value }
        
        return othersValue > 0 ? firstFive + [Entity(value: othersValue, label: "Остальные")] : firstFive
    }
    
    private func drawLegend(
        context: CGContext,
        entity: Entity,
        percentage: CGFloat,
        center: CGPoint,
        midAngle: CGFloat,
        radius: CGFloat
    ) {
        
        let textPosition = CGPoint(
            x: center.x + cos(midAngle) * radius,
            y: center.y + sin(midAngle) * radius
        )
        
        let text = "\(entity.label)\n\(Int(percentage * 100))%"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        
        text.draw(
            at: CGPoint(
                x: textPosition.x - 25,
                y: textPosition.y - 10
            ),
            withAttributes: attributes
        )
    }
}
