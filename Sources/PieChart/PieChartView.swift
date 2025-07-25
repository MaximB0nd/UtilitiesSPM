//
//  File.swift
//  Utilities
//
//  Created by Максим Бондарев on 25.07.2025.
//

import Foundation
import UIKit

@available(iOS 13.0, *)
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
    private let ringLineWidth: CGFloat = 24
    
    private let emptyColor: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor { trait in trait.userInterfaceStyle == .dark ? .systemGray : .systemGray4 }
        } else {
            return .lightGray
        }
    }()
    private let legendTextColor: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor { trait in trait.userInterfaceStyle == .dark ? .white : .black }
        } else {
            return .black
        }
    }()
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if entities.isEmpty {
            drawEmptyRing(context: context)
            drawEmptyLegend(context: context)
            return
        }
        
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
            drawPieRing(context: context, entities: entitiesToDraw)
            drawLegendInCenter(context: context, entities: entitiesToDraw)
            context.restoreGState()
        } else {
            drawPieRing(context: context, entities: prepareEntities(entities))
            drawLegendInCenter(context: context, entities: prepareEntities(entities))
        }
    }

    private func drawPieRing(context: CGContext, entities: [Entity]) {
        guard !entities.isEmpty else { return }
        let totalValue = entities.reduce(0) { $0 + $1.value }
        guard totalValue > 0 else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) * 0.4
        var startAngle: CGFloat = -.pi / 2
        for (index, entity) in entities.enumerated() {
            let percentage = CGFloat((entity.value as NSDecimalNumber).doubleValue / CGFloat((totalValue as NSDecimalNumber).doubleValue))
            let endAngle = startAngle + 2 * .pi * percentage
            let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            path.lineWidth = ringLineWidth
            colors[index % colors.count].setStroke()
            path.stroke()
            startAngle = endAngle
        }
    }
    
    private func drawEmptyRing(context: CGContext) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) * 0.4
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        path.lineWidth = ringLineWidth
        emptyColor.setStroke()
        path.stroke()
    }
    
    private func drawLegendInCenter(context: CGContext, entities: [Entity]) {
        guard !entities.isEmpty else { return }
        let totalValue = entities.reduce(0) { $0 + $1.value }
        guard totalValue > 0 else { return }
        let legendFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let dotSize: CGFloat = 10
        let spacing: CGFloat = 8
        let lineHeight: CGFloat = 22
        let legendWidth: CGFloat = 160
        let legendHeight: CGFloat = CGFloat(entities.count) * lineHeight
        let legendOrigin = CGPoint(x: bounds.midX - legendWidth/2, y: bounds.midY - legendHeight/2)
        for (i, entity) in entities.enumerated() {
            let percentage = CGFloat((entity.value as NSDecimalNumber).doubleValue / CGFloat((totalValue as NSDecimalNumber).doubleValue))
            let percentText = String(format: "%d%%", Int(percentage * 100))
            let label = "\(percentText) \(entity.label)"
            let y = legendOrigin.y + CGFloat(i) * lineHeight
            // draw color dot
            let dotRect = CGRect(x: legendOrigin.x, y: y + (lineHeight-dotSize)/2, width: dotSize, height: dotSize)
            let dotPath = UIBezierPath(ovalIn: dotRect)
            colors[i % colors.count].setFill()
            dotPath.fill()
            // draw text
            let textRect = CGRect(x: legendOrigin.x + dotSize + spacing, y: y, width: legendWidth - dotSize - spacing, height: lineHeight)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: legendFont,
                .foregroundColor: legendTextColor
            ]
            (label as NSString).draw(in: textRect, withAttributes: attributes)
        }
    }
    
    private func drawEmptyLegend(context: CGContext) {
        let legendFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let text = "Нет данных"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: legendFont,
            .foregroundColor: legendTextColor.withAlphaComponent(0.5)
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let rect = CGRect(x: bounds.midX - size.width/2, y: bounds.midY - size.height/2, width: size.width, height: size.height)
        (text as NSString).draw(in: rect, withAttributes: attributes)
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
