const chartFont = {
  family: "DM Sans",
  size: 10,
};

Chart.defaults.font = chartFont;
Chart.defaults.color = "#9a9cac";
Chart.defaults.animation.duration = 650;

const gridColor = "#efeff5";
const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

new Chart(document.getElementById("salesTrendChart"), {
  type: "line",
  data: {
    labels: months,
    datasets: [
      {
        label: "Actual sales",
        data: [5.4, 5.9, 6.2, 6.8, 7.1, 7.6, 8.3, 8.1, 8.8, 9.2, 10.1, 10.8],
        borderColor: "#6f5ce7",
        backgroundColor: "rgba(111, 92, 231, .10)",
        fill: true,
        tension: 0.4,
        pointRadius: 0,
        pointHoverRadius: 4,
        borderWidth: 2.5,
      },
      {
        label: "Previous year",
        data: [4.8, 5.0, 5.4, 5.8, 6.1, 6.4, 6.9, 7.0, 7.4, 7.8, 8.2, 8.9],
        borderColor: "#d7d0ff",
        fill: false,
        tension: 0.4,
        pointRadius: 0,
        borderWidth: 2,
        borderDash: [4, 4],
      },
    ],
  },
  options: {
    maintainAspectRatio: false,
    interaction: { intersect: false, mode: "index" },
    plugins: { legend: { display: false }, tooltip: { backgroundColor: "#26243f", padding: 10, displayColors: true, callbacks: { label: (context) => ` $${context.raw.toFixed(1)}M` } } },
    scales: {
      x: { grid: { display: false }, border: { display: false }, ticks: { padding: 8 } },
      y: { beginAtZero: true, max: 12, ticks: { stepSize: 3, padding: 10, callback: (value) => `$${value}M` }, grid: { color: gridColor }, border: { display: false } },
    },
  },
});

new Chart(document.getElementById("categoryChart"), {
  type: "bar",
  data: {
    labels: ["Bikes", "Accessories", "Clothing", "Components"],
    datasets: [{ data: [50.8, 19.4, 12.1, 8.5], backgroundColor: ["#6f5ce7", "#9f8ff3", "#c7bdf8", "#e7e2ff"], borderRadius: 5, borderSkipped: false, barThickness: 22 }],
  },
  options: {
    maintainAspectRatio: false,
    plugins: { legend: { display: false }, tooltip: { backgroundColor: "#26243f", callbacks: { label: (context) => ` $${context.raw}M` } } },
    scales: {
      x: { grid: { display: false }, border: { display: false }, ticks: { padding: 6, font: { size: 9 } } },
      y: { beginAtZero: true, max: 60, ticks: { stepSize: 20, callback: (value) => `$${value}M` }, grid: { color: gridColor }, border: { display: false } },
    },
  },
});

new Chart(document.getElementById("territoryChart"), {
  type: "doughnut",
  data: { labels: ["Northwest", "Southwest", "Canada", "Central", "Other"], datasets: [{ data: [28, 22, 18, 17, 15], backgroundColor: ["#6f5ce7", "#9584ee", "#b7aaf5", "#d4cbfa", "#e9e5ff"], borderWidth: 0, hoverOffset: 4 }] },
  options: { maintainAspectRatio: false, cutout: "74%", plugins: { legend: { display: false }, tooltip: { backgroundColor: "#26243f", callbacks: { label: (context) => ` ${context.label}: ${context.raw}%` } } } },
});

document.querySelector(".mobile-menu").addEventListener("click", () => {
  document.querySelector(".sidebar").classList.toggle("open");
});

document.querySelectorAll(".nav-item").forEach((item) => {
  item.addEventListener("click", () => document.querySelector(".sidebar").classList.remove("open"));
});
