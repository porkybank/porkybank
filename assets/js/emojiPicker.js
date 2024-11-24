const emojiPicker = {
  mounted() {
    const pickerOptions = {
      onEmojiSelect: ({ native }) => {
        this.pushEventTo("#emoji-picker", "emoji_selected", { emoji: native });
      },
      theme: "light",
      previewPosition: "none",
      maxFrequentRows: 0,
    };
    const button = this.el.querySelector("button");
    const container = this.el.querySelector("#emoji-picker-container");

    button.addEventListener("click", (e) => {
      e.preventDefault();
      container.appendChild(new EmojiMart.Picker(pickerOptions));
      container.classList.add("border", "border-zinc-200");
    });

    window.addEventListener("phx:kill_emoji_picker", (e) => {
      container.innerHTML = "";
      container.classList.remove("border", "border-zinc-200");
    });
  },
};

export default emojiPicker;
