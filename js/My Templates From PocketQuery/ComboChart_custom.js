<script>
PocketQuery.chart('ComboChart', {
  height: 500,
  width: 850,
  seriesType: 'bars', // Основной тип - столбцы
  series: {
    0: { type: 'bars', color: '#4e79a7' }, // Первая серия - столбцы
    1: { type: 'line', color: '#e15759', lineWidth: 3 } // Вторая - линия
  },
  legend: { position: 'top' },
  hAxis: { title: 'Дата', format: 'MMM yyyy' },
  vAxis: { 
    title: 'Значения',
    viewWindow: { min: 0 } // Минимальное значение оси Y
  },
  backgroundColor: 'transparent',
  animation: { duration: 800 }
});
</script>