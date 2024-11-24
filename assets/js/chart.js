import Chart from "chart.js/auto";

import { transparentize } from "./utils/chart";

Chart.defaults.font.weight = "bold";
Chart.defaults.font.size = 16;

const chart = () => {
  return {
    mounted() {
      this.init();

      window?.addEventListener("phx:chart-updated", this.init.bind(this));
    },
    init() {
      const ctx = this.el.getContext("2d");
      const dataset = JSON.parse(this.el.dataset.chart);

      if (!this.chart) {
        this.chart = new Chart(ctx, {
          type: "bar",
          data: {
            labels: dataset.map((data) => {
              return data.emoji;
            }),
            datasets: this.dataToDatasets(dataset),
          },
          options: {
            maintainAspectRatio: false,
            indexAxis: "y",
            plugins: {
              legend: {
                display: false,
              },
              tooltip: {
                bodyFont: {
                  size: 12,
                },
                titleFont: {
                  size: 12,
                },
                xAlign: "left",
                padding: 4,
                displayColors: false,
                callbacks: {
                  label: (context) => {
                    const data = dataset[context.dataIndex];
                    return (
                      data.emoji +
                      " " +
                      data.label +
                      ": " +
                      data.amount_formatted
                    );
                  },
                  title: (context) => {
                    return null;
                  },
                },
              },
            },
            scales: {
              x: {
                display: false,
              },
              y: {
                grid: {
                  display: false,
                },
              },
            },
          },
        });
      } else {
        this.chart.data.datasets = this.dataToDatasets(dataset);
        this.chart.update("none");
      }
    },
    dataToDatasets(dataset) {
      return [
        {
          data: dataset.map((data) => {
            return data.amount;
          }),
          backgroundColor: dataset.map((data) => {
            return data.color
              ? transparentize(data.color, 0.5)
              : "rgba(0, 0, 0, 0.1)";
          }),
          borderColor: dataset.map((data) => {
            return data.color || "rgba(0, 0, 0, 0.1)";
          }),
          borderWidth: dataset.map((data) => {
            return 2;
          }),
          borderRadius: dataset.map((data) => {
            return Number.MAX_VALUE;
          }),
        },
      ];
    },
  };
};

export default chart;
