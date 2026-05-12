import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Location
import qs.Widgets
import "WeatherUtils.js" as Utils

NBox {
  id: root
  property int forecastSlots: 6
  property bool showLocation: true
  property bool showEffects: Settings.data.location.weatherShowEffects
  readonly property bool weatherReady: Settings.data.location.weatherEnabled && !!LocationService.data.weather

  readonly property int code: weatherReady ? LocationService.data.weather.current_weather.weathercode : 0
  readonly property bool isDay: weatherReady ? LocationService.data.weather.current_weather.is_day : true
  readonly property bool isRaining: (code >= 51 && code <= 67) || (code >= 80 && code <= 82)
  readonly property bool isSnowing: (code >= 71 && code <= 77) || (code >= 85 && code <= 86)
  readonly property bool isCloudy: code === 3
  readonly property bool isFoggy: code >= 40 && code <= 49
  readonly property bool isClearDay: code === 0 && isDay
  readonly property bool isClearNight: code === 0 && !isDay

  visible: Settings.data.location.weatherEnabled
  implicitHeight: Math.max(100 * Style.uiScaleRatio, content.implicitHeight + (Style.marginL * 2))

  function isRainCode(c) {
    return (c >= 51 && c <= 67) || (c >= 80 && c <= 82) || (c >= 95 && c <= 99);
  }

  function isDayForHour(hourlyTimeStr, dailyData) {
    var d = new Date(hourlyTimeStr.replace(/-/g, "/"));
    for (var i = 0; i < dailyData.time.length; i++) {
      var dayDate = new Date(dailyData.time[i].replace(/-/g, "/"));
      if (d.toDateString() === dayDate.toDateString()) {
        var sunrise = new Date(dailyData.sunrise[i]).getTime();
        var sunset = new Date(dailyData.sunset[i]).getTime();
        var t = d.getTime();
        return t >= sunrise && t <= sunset;
      }
    }
    return d.getHours() >= 6 && d.getHours() <= 20;
  }

  function hourlySymbol(code, isDay) {
    if (code === 0)
      return isDay ? "weather-sun" : "weather-moon";
    if (code === 1 || code === 2)
      return isDay ? "weather-cloud-sun" : "weather-moon-stars";
    if (code === 3)
      return "weather-cloud";
    if (code >= 45 && code <= 48)
      return "weather-cloud-haze";
    if (code >= 51 && code <= 67)
      return "weather-cloud-rain";
    if (code >= 80 && code <= 82)
      return "weather-cloud-rain";
    if (code >= 71 && code <= 77)
      return "weather-cloud-snow";
    if (code >= 85 && code <= 86)
      return "weather-cloud-snow";
    if (code >= 95 && code <= 99)
      return "weather-cloud-lightning";
    return "weather-cloud";
  }

  Loader {
    anchors.fill: parent
    active: root.showEffects && (isRaining || isSnowing || isCloudy || isFoggy || isClearDay || isClearNight)
    sourceComponent: ShaderEffect {
      property real time: 0
      NumberAnimation on time { from: 0; to: 1000; duration: 100000; loops: Animation.Infinite }
      anchors.fill: parent
      anchors.margins: isRaining ? Style.marginXL : root.border.width
      property var source: ShaderEffectSource { sourceItem: content; hideSource: root.isRaining }
      property real itemWidth: width; property real itemHeight: height
      property color bgColor: root.color
      property real cornerRadius: isRaining ? 0 : (root.radius - root.border.width)
      property real alternative: isFoggy
      fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/" + (isSnowing ? "weather_snow" : isRaining ? "weather_rain" : (isCloudy || isFoggy) ? "weather_cloud" : isClearDay ? "weather_sun" : "weather_stars") + ".frag.qsb")
    }
  }

  ColumnLayout {
    id: content
    anchors.fill: parent; anchors.margins: Style.marginL; spacing: Style.marginM; clip: true

    RowLayout {
      Layout.fillWidth: true; spacing: Style.marginS
      Item { Layout.preferredWidth: Style.marginXXS }
      RowLayout {
        spacing: Style.marginL; Layout.fillWidth: true
        NIcon {
          icon: weatherReady ? LocationService.weatherSymbolFromCode(code) : "weather-cloud-off"
          pointSize: Style.fontSizeXXXL * 1.75; color: Color.mPrimary
        }
        ColumnLayout {
          spacing: Style.marginXXS
          NText {
            text: Settings.data.location.name.split(",")[0]
            pointSize: Style.fontSizeL; font.weight: Style.fontWeightBold
            visible: showLocation && !Settings.data.location.hideWeatherCityName
          }
          RowLayout {
            NText {
              visible: weatherReady
              text: weatherReady ? Utils.formatTemp(LocationService.data.weather.current_weather.temperature, Settings.data.location.useFahrenheit, true, LocationService) : ""
              pointSize: showLocation ? Style.fontSizeXL : Style.fontSizeXL * 1.6; font.weight: Style.fontWeightBold
            }
            NText {
              text: weatherReady ? `(${LocationService.data.weather.timezone_abbreviation})` : ""
              pointSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant
              visible: weatherReady && showLocation && !Settings.data.location.hideWeatherTimezone
            }
          }
        }
      }
    }

    NDivider { visible: weatherReady; Layout.fillWidth: true }

    RowLayout {
      visible: weatherReady; Layout.fillWidth: true; spacing: Style.marginM
      Repeater {
        model: {
          if (!weatherReady) return 0;
          var h = LocationService.data.weather.hourly;
          if (!h || !h.time) return 0;
          return Math.min(root.forecastSlots, Math.floor(h.time.length / 2));
        }
        delegate: ColumnLayout {
          Layout.fillWidth: true; spacing: Style.marginXS
          Item { Layout.fillWidth: true }

          NText {
            Layout.alignment: Qt.AlignCenter
            property int hourIdx: index * 2
            property var h: LocationService.data.weather.hourly
            text: {
              if (index === 0) return "现在";
              var d = new Date(h.time[hourIdx].replace(/-/g, "/"));
              var hh = d.getHours();
              return (hh < 10 ? "0" : "") + hh + ":00";
            }
            color: Color.mOnSurface
          }

          NIcon {
            Layout.alignment: Qt.AlignCenter
            property int hourIdx: index * 2
            property var h: LocationService.data.weather.hourly
            property int wcode: h ? h.weathercode[hourIdx] : 0
            property bool day: h ? root.isDayForHour(h.time[hourIdx], LocationService.data.weather.daily) : true
            icon: root.hourlySymbol(wcode, day)
            pointSize: Style.fontSizeXXL * 1.6; color: Color.mPrimary
          }

          NText {
            Layout.alignment: Qt.AlignCenter
            property int hourIdx: index * 2
            property var h: LocationService.data.weather.hourly
            text: h ? Utils.formatTemp(h.temperature_2m[hourIdx], Settings.data.location.useFahrenheit, false, LocationService) + "°" : ""
            pointSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant
          }

          NText {
            Layout.alignment: Qt.AlignCenter
            property int hourIdx: index * 2
            property var h: LocationService.data.weather.hourly
            property int wcode: h ? h.weathercode[hourIdx] : 0
            property int prob: h ? (h.precipitation_probability ? h.precipitation_probability[hourIdx] : 0) : 0
            text: prob + "%"
            visible: h && root.isRainCode(wcode) && prob > 0
            pointSize: Style.fontSizeXXS; color: "#64b5f6"
          }
        }
      }
    }
    Loader { active: !weatherReady; Layout.alignment: Qt.AlignCenter; sourceComponent: NBusyIndicator {} }
  }
}
