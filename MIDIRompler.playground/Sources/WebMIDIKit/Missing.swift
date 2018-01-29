import Darwin

func AudioGetCurrentHostTime() -> UInt64 {
    return mach_absolute_time()
}
func AudioConvertNanosToHostTime(_ inNanos: UInt64) -> UInt64 {
    var timeBaseInfo = mach_timebase_info_data_t()
    mach_timebase_info(&timeBaseInfo)
    return inNanos * UInt64(timeBaseInfo.denom) / UInt64(timeBaseInfo.numer)
}
