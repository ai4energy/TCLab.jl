module TCLab

include("labtime.jl")
include("version.jl")
include("utils.jl")


sep = ' '  # command/value separator in TCLab firmware

arduinos = [
    ("USB VID:PID=16D0:0613", "Arduino Uno"),
    ("USB VID:PID=1A86:7523", "NHduino"),
    ("USB VID:PID=2341:8036", "Arduino Leonardo"),
    ("USB VID:PID=2A03", "Arduino.org device"),
    ("USB VID:PID", "unknown device")
]

_sketchurl = "https://github.com/jckantor/TCLab-sketch"
_connected = false












end # module TCLab
