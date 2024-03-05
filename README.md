# (System)Verilog Miscellaneous

Здесь находится набор RTL-модулей на Verilog и SystemVerilog, написанных мной в разное время, в связи с учебой либо работой. Можно считать это неким подобием портфолио. Собранные здесь модули предназначаются для совершенно разных задач. Стоит обратить внимание, что модули писались в разное время, в моменты, когда у меня было разное количество опыта, в связи с чем качество отдельных модулей может различаться.

## Список модулей

Краткое описание модулей в репозитории:

1. **Wavelet-Transformer** - Wavelet-преобразователь. Дипломная бакалаврская работа. Набор модулей, выполняющих вейвлет-преобразование двумерного изображения. Преобразование происходит при помощи вейвлета `CDF5,3` посредством лифтинговой схемы. Всю конвейеризацию входных данных, необходимую для непрерывной подачи оных в модуль непосредственно преобразования, конструкция берет на себя.
2. **AXI-Interconnect** - AXI-коммутатор по принципу Many-to-One, для нескольких интерфейсов типа Master и одного интерфейса типа Slave. Поддерживаются одновременные транзакции чтения и записи от одного и того же Master, есть возможность поддержки мультитранзакций при помощи `AXI ID`.
3. **AXI Misc** - небольшой набор модулей, в той или иной степени связанных с протоколами `AXI`, `AXI-Lite`, `AXI-Stream`, некоторые - весьма косвенно.
	- `axis_bit_reverser` - побитовое обращение данных на шине `AXI-Stream`;
	- `gpc_axi_register` - преобразователь одиночных посылок `AXI-Stream` с шириной данных в 512 бит в `AXI-Lite` 64-бит и наоборот;
	- `rx_timing_checker`, `tx_timing_checker` - модули, находящиеся по разные стороны передающего данные канала, предназначены для замера задержки данных в оном канале.
