//
//  HealthController.swift
//  Taylor
//
//  Created by Kevin Sum on 19/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import Charts
import MagicalRecord
import HexColors
import UIKit

class HealthController: BaseViewController {

    @IBOutlet weak var weekButton: UIButton!
    @IBOutlet weak var monthButton: UIButton!
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var optionView: HealthOptions!
    
    let daySeconds: Double = 60*60*24
    var showWeek = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = false
        chartView.highlightPerDragEnabled = true
        chartView.chartDescription?.enabled = false
//        chartView.backgroundColor = .white
        
        chartView.legend.enabled = false
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
//        xAxis.labelFont = .systemFont(ofSize: 10, weight: .light)
        xAxis.labelTextColor = .white
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = true
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity = daySeconds
        xAxis.valueFormatter = XAxisDateFormatter()
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelPosition = .outsideChart
//        leftAxis.labelFont = .systemFont(ofSize: 12, weight: .light)
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled = true
//        leftAxis.axisMinimum = 0
//        leftAxis.axisMaximum = 170
        leftAxis.yOffset = -9
//        leftAxis.xOffset = -10
        leftAxis.labelTextColor = .white
        
        
        chartView.rightAxis.enabled = false
        
        chartView.legend.form = .line
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setMonthStep(orWeek: showWeek)
    }
    
    func setMonthStep(orWeek isWeek: Bool) {
        showWeek = isWeek
        optionView.setupMonth(OrWeek: isWeek)
        let steps = Step.getSet(ofWeek: isWeek)
        let values = steps.sorted { (step1, step2) -> Bool in
            return step1.key < step2.key
            }.map { (step) -> ChartDataEntry in
                log.debug(step.value)
                return ChartDataEntry(x: step.key, y: Double(step.value))
        }
        let set = LineChartDataSet(values: values, label: "Steps")
        set.axisDependency = .left
        set.setColor(UIColor("#fddfc0")!)
        set.lineWidth = 1.5
        set.drawCirclesEnabled = false
        set.drawValuesEnabled = false
        set.fillAlpha = 0.26
        set.fillColor = UIColor("#fddfc0")!
        set.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set.drawCircleHoleEnabled = false
        set.mode = .horizontalBezier

        let data = LineChartData(dataSet: set)
        data.setValueTextColor(.white)
        data.highlightEnabled = false
        //        data.setValueFont(.systemFont(ofSize: 9, weight: .light))

        chartView.data = data
        chartView.animate(xAxisDuration: 1)
    }
    
    @IBAction func didButtonClick(_ sender: UIButton) {
        if sender == weekButton {
            weekButton.setTitleColor(UIColor("#FDDFC0"), for: .normal)
            monthButton.setTitleColor(UIColor("#9B9B9B"), for: .normal)
            setMonthStep(orWeek: true)
        } else if sender == monthButton {
            weekButton.setTitleColor(UIColor("#9B9B9B"), for: .normal)
            monthButton.setTitleColor(UIColor("#FDDFC0"), for: .normal)
            setMonthStep(orWeek: false)
        }
    }
}

class XAxisDateFormatter: NSObject, IAxisValueFormatter {
    private let hourFormat = DateFormatter()
    private let dayFormat = DateFormatter()
    
    override init() {
        super.init()
        dayFormat.dateFormat = "dd"
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        return dayFormat.string(from: date)
    }
}
