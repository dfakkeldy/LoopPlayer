//
//  BookLoop_WidgetBundle.swift
//  BookLoop Widget
//
//  Created by Dan Fakkeldy on 2026-05-02.
//

import WidgetKit
import SwiftUI

@main
struct BookLoop_WidgetBundle: WidgetBundle {
    var body: some Widget {
        BookLoop_Widget()
        BookLoop_WidgetControl()
    }
}
