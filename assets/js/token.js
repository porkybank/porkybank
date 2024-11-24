const token = () => {
  return {
    mounted() {
      const button = document.getElementById("link-button");

      const createPlaidLink = () => {
        const button = document.getElementById("link-button");

        this.plaidHandler = Plaid.create({
          env: button.dataset.env,
          clientName: "Porkybank",
          token: button.dataset.linkToken,
          product: ["transactions"],
          onSuccess: (public_token, metadata) => {
            this.pushEvent("plaid_success", {
              account_id: metadata.account.id,
              public_token: public_token,
              institution_name: metadata.institution.name,
            });
          },
          onEvent: (name, metadata) => {
            console.log(name, metadata);
          },
          // ... other configurations ...
        });
      };

      button.addEventListener("click", (e) => {
        e.preventDefault();
        createPlaidLink();
        this.plaidHandler.open();
      });
    },
  };
};

export default token;
