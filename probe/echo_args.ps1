# Native program that reports the arguments it actually received, so MSYS
# argument conversion is measured rather than assumed.
foreach ($a in $args) { "##A##ARG=$a" }
