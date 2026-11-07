# Send bitmaps to mirai workers

A 32-bit bitmap travels to `mirai` daemons with no configuration: R's
own serialisation writes it in the portable format. The configuration
`roar_serial_config()` returns, for `mirai::daemons(serial = )`, is
needed for the 64-bit class, which is an external pointer; it is
harmless for 32-bit bitmaps, and only the bitmaps actually sent are
serialised.

## Usage

``` r
roar_serial_config()
```

## Value

A serialisation configuration from
[`mirai::serial_config()`](https://nanonext.r-lib.org/reference/serial_config.html).

## Examples

``` r
if (requireNamespace("mirai", quietly = TRUE)) {
  cfg <- roar_serial_config()
  # mirai::daemons(2, serial = cfg)
}
```
