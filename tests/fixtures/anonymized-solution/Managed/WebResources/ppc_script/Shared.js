var Ppc = Ppc || {};
Ppc.Helper = Ppc.Helper || {};

Ppc.Helper.setTabVisibility = (formContext, tabName, isVisible) => {
  return {
    formContext: formContext,
    tabName: tabName,
    isVisible: isVisible
  };
};