import 'interpreter.dart';

/// Interpolates the given [rawString] and returns the
/// interpolated string.
///
/// String interpolation means that certain parts of the string
/// can be encoded to indicate that the part should be replaced
/// with some value instead.
///
/// An encoding always starts with a `$` and is followed by the key
/// or value that should be interpolated.
///
/// For example, the part `$tags` will be replaced with the list
/// of all currently stored tags in [context].
///
/// Possible interpolation keys are:
/// * `$<counter-name>`: Replaces with the counter´s value.
/// * `$tags`: Replaces with a comma-separated list of all tags.
/// * `$<tag-key>`: Replaces with the value of the tag.
/// * `$userInputText`: Replaces with the value of the most recent
/// free-text input.
String interpolateString(RuntimeContext context, String rawString) {
  var regex = RegExp(r"\$[^\s]+");
  String interpolated = rawString.replaceAllMapped(regex, (match) {
    // Start at start+1 as we do not want the $ in our template.
    var template = rawString.substring(match.start + 1, match.end);

    // Check if we are interpolating a counter (by name).
    if (context.counters.containsKey(template)) {
      var counterValue = context.counters[template].value;
      return counterValue.toString();
    }

    // Check if we are interpolating the tags.
    if (template == 'tags') {
      return context.tags.toString();
    }

    // Check if we are interpolating a single tag (by key).
    if (context.counters.containsKey(template)) {
      var counterValue = context.counters[template].value;
      return counterValue.toString();
    }

    // Unknown interpolation value.
    // Instead of throwing an error here we simply return the template.
    return template;
  });
  return interpolated;
}
