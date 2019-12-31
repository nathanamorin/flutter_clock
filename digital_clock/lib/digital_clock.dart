// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _Element {
  background,
  text,
}

final _lightTheme = {
  _Element.background: Colors.white,
  _Element.text: Colors.black,
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.text: Colors.white,
};

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      // Update once per second.
      _timer = Timer(
        Duration(seconds: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  Widget _createCol(TextStyle defaultStyle, String value, TextStyle style,
      {int minSize = 2}) {
    return Container(
      child: DefaultTextStyle(
          style: defaultStyle, child: Text(value, style: style)),
      padding: EdgeInsets.all(5.0),
    );
  }

  Widget _createRow(String currentValue, List<String> values,
      TextStyle defaultStyle, int maxDisplayedValues) {
    final double fontSize =
        MediaQuery.of(context).size.width / (maxDisplayedValues * 3.0);

    final TextStyle styleCurrent = TextStyle(
        fontWeight: FontWeight.bold, fontSize: fontSize, color: Colors.red);
    final TextStyle styleOther =
        TextStyle(fontWeight: FontWeight.normal, fontSize: fontSize);

    List<Widget> cols = new List();

    // Set Current Value
    cols.add(_createCol(defaultStyle, currentValue, styleCurrent));
    final int startIndex = values.indexWhere((ele) {
      return ele == currentValue;
    });

    // Add values to the left & right of current value until maxDisplayedValues is reached
    int currentOffset = 1;
    while (cols.length + 2 <= maxDisplayedValues) {
      final int after = (startIndex + currentOffset) % values.length;
      final int before = (startIndex - currentOffset) % (values.length - 1);
      cols.add(_createCol(defaultStyle, values[after], styleOther));
      cols.insert(0, _createCol(defaultStyle, values[before], styleOther));
      currentOffset += 1;
    }

    return Row(
      children: cols,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set styles
    final colors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;

    final textStyle =
        TextStyle(color: colors[_Element.text], fontFamily: 'VT323');

    // Set time values
    final year = DateFormat('yyyy').format(_dateTime);
    final years = List.generate(12, (m) {
      return (_dateTime.year + (m - 6)).toString();
    });

    final month = DateFormat('MMM').format(_dateTime);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final dayOfMonth = DateFormat('d').format(_dateTime);
    final daysOfMonth = List.generate(8, (d) {
      return DateFormat('dd').format(_dateTime.add(Duration(days: d - 4)));
    });

    final hourFormat = widget.model.is24HourFormat ? 'HH' : 'hh';
    final hour = DateFormat(hourFormat).format(_dateTime);
    final hours = List.generate(3, (h) {
      return DateFormat(hourFormat)
          .format(_dateTime.add(Duration(hours: (h - 1))));
    });

    final minute = _dateTime.minute.toString().padLeft(2, '0');
    final minutes = List.generate(60, (m) {
      return (m).toString().padLeft(2, '0');
    });

    final second = _dateTime.second.toString().padLeft(2, '0');
    final seconds = List.generate(60, (s) {
      return (s).toString().padLeft(2, '0');
    });

    return Container(
      color: colors[_Element.background],
      child: Stack(children: <Widget>[
        Column(children: <Widget>[
          _createRow(year, years, textStyle, 10),
          _createRow(month, months, textStyle, 10),
          _createRow(dayOfMonth, daysOfMonth, textStyle, 7),
          _createRow(hour, hours, textStyle, 3),
          _createRow(minute, minutes, textStyle, 5),
          _createRow(second, seconds, textStyle, 10),
        ]),
        Container(
          child: DefaultTextStyle(
            child: Text(widget.model.lowString,
                style: TextStyle(color: Colors.blue)),
            style: textStyle,
          ),
          alignment: Alignment(-1, 1),
          padding: EdgeInsets.only(left: 5, bottom: 2),
        ),
        Container(
          child: DefaultTextStyle(
            child: Text(widget.model.highString,
                style: TextStyle(color: Colors.red)),
            style: textStyle,
          ),
          alignment: Alignment(1, 1),
          padding: EdgeInsets.only(right: 5, bottom: 2),
        ),
        Container(
          child: RichText(
              text: TextSpan(children: <TextSpan>[
            TextSpan(
                text: widget.model.weatherString.toUpperCase(),
                style: TextStyle(color: colors[_Element.text])),
            TextSpan(
                text: " in ",
                style: TextStyle(
                  color: Colors.grey,
                )),
            TextSpan(
                text: widget.model.location,
                style: TextStyle(color: Colors.grey)),
          ], style: textStyle)),
          alignment: Alignment(0, 1),
          padding: EdgeInsets.only(bottom: 2),
        )
      ]),
    );
  }
}
