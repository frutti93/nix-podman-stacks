import DefaultTheme from "vitepress/theme";
import "./custom.css";
import CustomOutlineItem from "./VPDocOutlineItem.vue";
export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component("VPDocOutlineItem", CustomOutlineItem);
  },
};
