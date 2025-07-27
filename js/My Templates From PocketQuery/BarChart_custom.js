<script>
PocketQuery.chart('BarChart', {
  height: 450,
  width: 800,
  legend: { position: 'top', textStyle: { color: '#555', fontSize: 12 } },
  colors: ['#4e79a7', '#f28e2b', '#e15759'], // Кастомные цвета
  backgroundColor: 'transparent',
  animation: { duration: 1000, easing: 'out' }, // Анимация
  hAxis: { 
    title: 'Количество', 
    titleTextStyle: { color: '#333', italic: false },
    gridlines: { color: '#eee' }
  },
  vAxis: { 
    title: 'Интервалы', 
    titleTextStyle: { color: '#333', italic: false },
    minValue: 0 
  },
  bar: { groupWidth: '70%' }, // Ширина столбцов
  isStacked: false // или true для stacked
});
</script>