#using TCLab
using LibSerialPort
sp=LibSerialPort.Lib.sp_get_port_by_name("COM3")
LibSerialPort.Lib.sp_get_age_lib_version()
LibSerialPort.Lib.sp_get_port_description(sp.ref)
LibSerialPort.Lib.sp_get_port_usb_bus_address(sp.ref)
LibSerialPort.Lib.sp_get_port_usb_vid_pid(sp.ref)
LibSerialPort.Lib.sp_get_port_usb_manufacturer(sp.ref)
LibSerialPort.Lib.sp_get_port_usb_product(sp.ref)
LibSerialPort.Lib.sp_get_port_usb_serial(sp.ref)
LibSerialPort.Lib.sp_get_lib_version_string()
LibSerialPort.Lib.sp_get_current_lib_version()
LibSerialPort.Lib.sp_get_package_version_string()
LibSerialPort.Lib.sp_get_major_package_version()
LibSerialPort.Lib.sp_get_micro_package_version()
LibSerialPort.Lib.sp_get_minor_package_version()
LibSerialPort.Lib.sp_get_port_name(sp.ref)
LibSerialPort.Lib.sp_get_port_transport(sp.ref)
LibSerialPort.Lib.sp_get_port_bluetooth_address(sp.ref)
LibSerialPort.get_port_list()
LibSerialPort.Lib.sp_get_config(sp.ref)
LibSerialPort.get_port_settings(sp.ref)
LibSerialPort.print_port_settings(sp.ref)
config = LibSerialPort.sp_get_config(sp.ref)
LibSerialPort.sp_get_config_baudrate(config)
LibSerialPort.open(sp, 19600)
LibSerialPort.isopen(sp)
LibSerialPort.close(sp)
LibSerialPort.isopen(sp)