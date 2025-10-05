document.addEventListener("DOMContentLoaded", () => {
  // ================================
  // VILLAGE DRILLDOWN LOGIC
  // ================================
  fetch("/data")
    .then(res => res.json())
    .then(data => {
      const stateDropdown = document.getElementById("stateDropdown");
      const districtDropdown = document.getElementById("districtDropdown");
      const blockDropdown = document.getElementById("blockDropdown");
      const villageDropdown = document.getElementById("villageDropdown");
      const results = document.getElementById("cropResults");

      if (!stateDropdown || !districtDropdown || !blockDropdown || !villageDropdown) {
        return; // not on village page
      }

      // Populate states
      for (let state in data) {
        stateDropdown.add(new Option(state, state));
      }

      stateDropdown.onchange = () => {
        districtDropdown.length = 1;
        blockDropdown.length = 1;
        villageDropdown.length = 1;

        if (data[stateDropdown.value]) {
          for (let district in data[stateDropdown.value]) {
            districtDropdown.add(new Option(district, district));
          }
        }
      };

      districtDropdown.onchange = () => {
        blockDropdown.length = 1;
        villageDropdown.length = 1;

        const districtData = data[stateDropdown.value]?.[districtDropdown.value];
        if (districtData) {
          for (let block in districtData) {
            blockDropdown.add(new Option(block, block));
          }
        }
      };

      blockDropdown.onchange = () => {
        villageDropdown.length = 1;

        const villages = data[stateDropdown.value]?.[districtDropdown.value]?.[blockDropdown.value];
        if (villages) {
          for (let village of villages) {
            villageDropdown.add(new Option(village, village));
          }
        }
      };

      villageDropdown.onchange = () => {
        const state = stateDropdown.value;
        const district = districtDropdown.value;
        const block = blockDropdown.value;
        const village = villageDropdown.value;

        if (!state || !district || !block || !village) return;

        fetch(`/village-data/${state}/${district}/${block}/${village}`)
          .then(res => res.json())
          .then(cropData => {
            results.innerHTML = "";
            for (let crop in cropData) {
              const div = document.createElement("div");
              div.innerHTML = `<strong>${crop}:</strong> ${cropData[crop]}`;
              results.appendChild(div);
            }
          });
      };
    });

  // ================================
  // MARKET DASHBOARD LOGIC
  // ================================
  let priceChartInstance = null;

  // Populate state dropdown for dashboard
  fetch("/data")
    .then(res => res.json())
    .then(data => {
      const stateSelect = document.getElementById("state");
      if (!stateSelect) return;

      Object.keys(data).forEach(state => {
        const opt = document.createElement("option");
        opt.value = state;
        opt.textContent = state;
        stateSelect.appendChild(opt);
      });
    });

  const stateSelect = document.getElementById("state");
  const mandiSelect = document.getElementById("mandi");
  const cropSelect = document.getElementById("crop");

  // State -> Mandis
  if (stateSelect && mandiSelect) {
    stateSelect.addEventListener("change", function () {
      const state = this.value;
      mandiSelect.innerHTML = "<option value=''>Select Mandi</option>";
      cropSelect.innerHTML = "<option value=''>Select Crop</option>";
      mandiSelect.disabled = true;
      cropSelect.disabled = true;

      if (!state) return;

      fetch(`/mandis/${encodeURIComponent(state)}`)
        .then(res => res.json())
        .then(mandis => {
          mandis.forEach(mandi => {
            const opt = document.createElement("option");
            opt.value = mandi;
            opt.textContent = mandi;
            mandiSelect.appendChild(opt);
          });
          mandiSelect.disabled = false;
        });
    });
  }

  // Mandi -> Crops
  if (mandiSelect && cropSelect) {
    mandiSelect.addEventListener("change", function () {
      const state = stateSelect.value;
      const mandi = this.value;

      cropSelect.innerHTML = "<option value=''>Select Crop</option>";
      cropSelect.disabled = true;

      if (!state || !mandi) return;

      fetch(`/crops/${encodeURIComponent(state)}/${encodeURIComponent(mandi)}`)
        .then(res => res.json())
        .then(crops => {
          crops.forEach(crop => {
            const opt = document.createElement("option");
            opt.value = crop;
            opt.textContent = crop;
            cropSelect.appendChild(opt);
          });
          cropSelect.disabled = false;
        });
    });
  }

  // Crop -> Prices
  if (cropSelect) {
    cropSelect.addEventListener("change", fetchPrices);
  }

  function fetchPrices() {
  const state = stateSelect.value;
  const mandi = mandiSelect.value;
  const crop = cropSelect.value;
  const ticker = document.getElementById("price-ticker");
  const tbody = document.querySelector("#priceTable tbody");
  const chartCanvas = document.getElementById("priceChart");
  const ctx = chartCanvas ? chartCanvas.getContext("2d") : null;

  if (!state || !mandi || !crop || !ctx) return;

  // Show loading
  ticker.innerHTML = `<span class="spinner"></span> Fetching latest prices…`;
  if (tbody) {
    tbody.innerHTML = `<tr><td colspan="3" class="loading-text">Loading data…</td></tr>`;
  }
  if (priceChartInstance) {
    priceChartInstance.destroy();
    priceChartInstance = null;
  }

  fetch(`/market-prices?state=${encodeURIComponent(state)}&mandi=${encodeURIComponent(mandi)}&crop=${encodeURIComponent(crop)}`)
    .then(res => res.json())
    .then(data => {
      if (data.error) {
        ticker.textContent = data.error;
        clearChartAndTable();
        return;
      }

      // === Update ticker ===
      const changePct = Number(data.latest.change_pct).toFixed(2);
      const changeClass = changePct >= 0 ? "up" : "down";
      ticker.innerHTML = `
        <span class="ticker-crop">${data.crop}</span> —
        <span class="ticker-price">₹${data.latest.modal_price}/quintal</span>
        <span class="ticker-change ${changeClass}">
          (${changePct}% vs 7d start)
        </span>
        <span class="ticker-avg">• 7d avg: ₹${data.latest.avg_7d}</span>
      `;

      // === Last 7 days ===
      const recentHistory = (data.history && data.history.length > 0)
        ? data.history.slice(-7)
        : [];

      if (recentHistory.length === 0) {
        ticker.textContent = "No recent price data available.";
        clearChartAndTable();
        return;
      }

      // === Chart ===
      const labels = recentHistory.map(h => h.date);
      const values = recentHistory.map(h => h.modal_price);

      priceChartInstance = new Chart(ctx, {
        type: 'line',
        data: {
          labels,
          datasets: [{
            label: `${data.crop} Price (₹/quintal)`,
            data: values,
            borderColor: '#4caf50',
            backgroundColor: 'rgba(76, 175, 80, 0.2)',
            fill: true,
            tension: 0.25,
            pointRadius: 3
          }]
        },
        options: {
          responsive: true,
          plugins: { tooltip: { mode: 'index', intersect: false } },
          scales: {
            y: { title: { display: true, text: '₹ / quintal' } },
            x: { title: { display: true, text: 'Date' } }
          }
        }
      });

      // === Table ===
      tbody.innerHTML = "";
      recentHistory.forEach(row => {
        const perKg = (Number(row.modal_price) / 100).toFixed(2);
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td>${row.date}</td>
          <td>₹${row.modal_price}</td>
          <td>₹${perKg}</td>
        `;
        tbody.appendChild(tr);
      });
    })
    .catch(err => {
      console.error(err);
      ticker.textContent = "Failed to fetch prices.";
      clearChartAndTable();
    });
}

function clearChartAndTable() {
  if (priceChartInstance) {
    priceChartInstance.destroy();
    priceChartInstance = null;
  }
  const tbody = document.querySelector("#priceTable tbody");
  if (tbody) {
    tbody.innerHTML = `<tr><td colspan="3" class="loading-text">No data available</td></tr>`;
  }
}
}
);
