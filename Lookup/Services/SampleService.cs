using System;
using System.Linq;

internal class SampleService
{
    public string GenerateSample(short i)
    {
        var bytes = Enumerable.Range(0, 8).Select(i => Convert.ToByte(i)).ToArray();
        return new Guid(i, Convert.ToInt16(i), Convert.ToInt16(i), bytes).ToString();
    }
}
