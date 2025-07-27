<script>
PocketQuery.chart('PieChart', {
  height: 500,
  width: 750,
  colors: ['#66c2a5', '#fc8d62', '#8da0cb', '#e78ac3'], // Пастельные цвета
  backgroundColor: 'transparent',
  pieSliceText: 'percentage', // или 'value', 'label'
  pieHole: 0.4, // Кольцевая диаграмма (0 = обычная, 0.4 = отверстие в центре)
  tooltip: { 
    showColorCode: true,
    textStyle: { fontSize: 12 }
  },
  legend: { 
    position: 'right', 
    alignment: 'center',
    textStyle: { color: '#555' } 
  },
  chartArea: { left: 20, top: 20, width: '90%', height: '90%' },
  slices: { 
    0: { offset: 0.1 }, // Выделение сектора (например, первого)
    2: { color: '#ffd700' } // Явное указание цвета для 3-го элемента
  }
});
</script>