/*\
created: 20240705071332247
title: $:/plugins/ThaddeusJiang/lego/dark-mode/dark.js
modified: 20240708081928386
tags: $:/plugins/ThaddeusJiang/lego $:/plugins/ThaddeusJiang/lego/dark-mode
type: application/javascript
module-type: macro
\*/
;(function () {
  /*jslint node: true, browser: true */
  /*global $tw: false */
  "use strict"

  /*
Information about this macro
*/

  exports.name = "dark"

  exports.params = []

  /*
Run the macro
*/
  exports.run = function () {
    const isDark = window.matchMedia("(prefers-color-scheme: dark)").matches

    const darkPalette = $tw.wiki.getTiddler("$:/values/dark-mode") // "$:/palettes/Twilight"
    const lightPalette = $tw.wiki.getTiddler("$:/values/light-mode") // "$:/palettes/Vanilla"

    // Create or update the tiddler
    $tw.wiki.addTiddler(
      new $tw.Tiddler(
        $tw.wiki.getCreationFields(),
        { title: "$:/palette", text: isDark ? darkPalette.fields.text : lightPalette.fields.text },
        $tw.wiki.getModificationFields()
      )
    )

    return ""
  }
})()
