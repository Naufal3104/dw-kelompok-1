const palette = {
  accent: "oklch(82% 0.15 80)",
  muted: "oklch(71% 0.01 250)",
  cool: "oklch(77% 0.12 245)",
  rule: "oklch(31% 0.01 250)",
  paper: "oklch(21% 0.009 250)",
  ink: "oklch(95% 0.005 250)",
};

Chart.defaults.font = {
  family: "Host Grotesk",
  size: 12,
};
Chart.defaults.color = palette.muted;
Chart.defaults.animation.duration = 420;

const axis = {
  x: {
    border: { display: false },
    grid: { display: false },
    ticks: { color: palette.muted, padding: 8 },
  },
  y: {
    border: { display: false },
    grid: { color: palette.rule },
    ticks: {
      color: palette.muted,
      padding: 8,
      callback: (value) => `$${value}M`,
    },
  },
};

const tooltip = {
  backgroundColor: palette.paper,
  borderColor: palette.rule,
  borderWidth: 1,
  titleColor: palette.ink,
  bodyColor: palette.muted,
  padding: 12,
};

new Chart(document.getElementById("salesTrendChart"), {
  type: "line",
  data: {
    labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
    datasets: [
      {
        label: "2014",
        data: [5.4, 5.9, 6.2, 6.8, 7.1, 7.6, 8.3, 8.1, 8.8, 9.2, 10.1, 10.8],
        borderColor: palette.accent,
        backgroundColor: "color-mix(in oklab, oklch(82% 0.15 80) 12%, transparent)",
        fill: true,
        tension: 0.36,
        pointRadius: 0,
        pointHoverRadius: 4,
        borderWidth: 2,
      },
      {
        label: "2013",
        data: [4.8, 5.0, 5.4, 5.8, 6.1, 6.4, 6.9, 7.0, 7.4, 7.8, 8.2, 8.9],
        borderColor: palette.muted,
        borderDash: [4, 4],
        fill: false,
        tension: 0.36,
        pointRadius: 0,
        borderWidth: 1.5,
      },
    ],
  },
  options: {
    maintainAspectRatio: false,
    interaction: { intersect: false, mode: "index" },
    plugins: {
      legend: { display: false },
      tooltip: {
        ...tooltip,
        callbacks: { label: (context) => ` ${context.dataset.label}: $${context.raw.toFixed(1)}M` },
      },
    },
    scales: { ...axis, y: { ...axis.y, max: 12, ticks: { ...axis.y.ticks, stepSize: 3 } } },
  },
});

new Chart(document.getElementById("categoryChart"), {
  type: "bar",
  data: {
    labels: ["Q1", "Q2", "Q3", "Q4"],
    datasets: [
      { label: "Bikes", data: [11.8, 12.5, 13.2, 13.3], backgroundColor: palette.accent, borderWidth: 0 },
      { label: "Accessories", data: [4.4, 4.8, 5.1, 5.1], backgroundColor: "oklch(69% 0.12 80)", borderWidth: 0 },
      { label: "Clothing", data: [2.7, 3.0, 3.1, 3.3], backgroundColor: "oklch(56% 0.08 80)", borderWidth: 0 },
      { label: "Components", data: [1.8, 2.0, 2.2, 2.5], backgroundColor: "oklch(43% 0.05 80)", borderWidth: 0 },
    ],
  },
  options: {
    maintainAspectRatio: false,
    plugins: { legend: { display: false }, tooltip },
    scales: {
      x: { ...axis.x, stacked: true },
      y: { ...axis.y, stacked: true, max: 24, ticks: { ...axis.y.ticks, stepSize: 6 } },
    },
  },
});

new Chart(document.getElementById("peopleChart"), {
  type: "bar",
  data: {
    labels: ["Northwest · S. Jackson", "Southwest · J. Adams", "Canada · T. Zheng", "Central · M. Lee", "Northeast · R. Diaz"],
    datasets: [
      {
        label: "Sales value",
        data: [9.4, 8.7, 7.9, 7.3, 6.8],
        backgroundColor: [palette.accent, "oklch(76% 0.12 80)", "oklch(68% 0.09 80)", "oklch(60% 0.07 80)", "oklch(51% 0.05 80)"],
        borderWidth: 0,
        borderRadius: 2,
        barThickness: 22,
      },
    ],
  },
  options: {
    indexAxis: "y",
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: { ...tooltip, callbacks: { label: (context) => ` $${context.raw.toFixed(1)}M` } },
    },
    scales: {
      x: { ...axis.y, max: 12, ticks: { ...axis.y.ticks, stepSize: 3 } },
      y: { ...axis.x, grid: { display: false } },
    },
  },
});

new Chart(document.getElementById("promotionChart"), {
  type: "bar",
  data: {
    labels: ["Offer #50", "Offer #16", "Offer #45", "Offer #20"],
    datasets: [
      { label: "Revenue lift", data: [31.8, 24.2, 18.6, 12.4], backgroundColor: palette.accent, borderWidth: 0, borderRadius: 2 },
      { label: "Discount used", data: [28.4, 21.3, 17.1, 11.6], backgroundColor: palette.cool, borderWidth: 0, borderRadius: 2 },
    ],
  },
  options: {
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: { ...tooltip, callbacks: { label: (context) => ` ${context.dataset.label}: ${context.raw}%` } },
    },
    scales: {
      x: { ...axis.x },
      y: { beginAtZero: true, max: 40, border: { display: false }, grid: { color: palette.rule }, ticks: { color: palette.muted, callback: (value) => `${value}%` } },
    },
  },
});

document.querySelectorAll(".control-button").forEach((button) => {
  button.addEventListener("click", () => {
    const group = button.closest(".control-group");
    group.querySelectorAll(".control-button").forEach((item) => item.classList.remove("is-selected"));
    button.classList.add("is-selected");
  });
});
