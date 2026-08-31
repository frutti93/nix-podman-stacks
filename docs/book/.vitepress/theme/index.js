import DefaultTheme from "vitepress/theme";
import CustomOutlineItem from "./VPDocOutlineItem.vue";

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    // Strip the `nps.stacks.<name>.` prefix from option names in the outline
    // (right sidebar) while leaving the full names in the page headings.
    app.component("VPDocOutlineItem", CustomOutlineItem);
  },
};
