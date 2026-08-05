var Ppc = Ppc || {};
Ppc.Order = Ppc.Order || {};
Ppc.Order.formScripts = Ppc.Order.formScripts || {};

Ppc.Order.formScripts.onLoad = (executionContext) => {
  var formContext = executionContext || { ui: { tabs: { get: function () { return { setVisible: function () { return $null; } }; } } } };
  Ppc.Helper.setTabVisibility(formContext, "tab_summary", true);
};
