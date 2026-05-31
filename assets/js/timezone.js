const Timezone = {
  mounted() {
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
    this.pushEvent("detect_timezone", { timezone: tz });
  }
};

export default Timezone;
