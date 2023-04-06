
{% docs quality_level %}

The quality levels "Qualitätsniveau" (QN) given here apply for the respective following columns. The values are the minima of the QN of the respective daily values. QN denotes the method of quality control, with which erroneous values are identified and apply for the whole set of parameters at a certain time. For the individual parameters there exist quality bytes in the internal DWD data base, which are not published here. Values identifed as wrong are not published. Various methods of quality control (at different levels) are employed to decide which value is identified as wrong. In the past, different procedures have been employed. The quality procedures are coded as following:

- \[1\] only formal control during decoding and import
- \[2\] controlled with individually defined criteria
- \[3\] ROUTINE control with QUALIMET and QCSY
- \[5\] historic, subjective procedures
- \[7\] ROUTINE control, not yet corrected
- \[8\] quality control outside ROUTINE
- \[9\] ROUTINE control, not all parameters corrected
- \[10\] ROUTINE control finished, respective corrections finished

{% enddocs %}
 
{% docs precipitation %}

RSKF precipitation form:
- \[0\] no precipitation (conventional or automatic measurement), relates to WMO code 10
- \[1\] only rain (before 1979)
- \[4\] unknown form of recorded precipitation
- \[6\] only rain; only liquid precipitation at automatic stations, relates to WMO code 11
- \[7\] only snow; only solid precipitation at automatic stations, relates to WMO code 12
- \[8\] rain and snow (and/or "Schneeregen"); liquid and solid precipitation at automatic stations, relates to WMO code 13
- \[9\] error or missing value or no automatic determination of precipitation form, relates to WMO code 15

{% enddocs %}