<script setup>
const props = defineProps({
  headers: {
    type: Array,
    required: true,
  },
  root: {
    type: Boolean,
    default: false,
  },
});

function onClick({ target: el }) {
  const id = el.href.split("#")[1];
  const heading = document.getElementById(decodeURIComponent(id));
  heading?.focus({ preventScroll: true });
}

// Drop the stack prefix (e.g. `nps.stacks.streaming.`) from option names so
// the outline stays readable, without altering the page headings.
function stripPrefix(title) {
  return title.replace(/^nps\.stacks\.[^.]+\./, "");
}
</script>

<template>
  <ul class="VPDocOutlineItem" :class="root ? 'root' : 'nested'">
    <li v-for="{ children, link, title } in headers">
      <a class="outline-link" :href="link" @click="onClick" :title="title">{{
        stripPrefix(title)
      }}</a>
      <template v-if="children?.length">
        <VPDocOutlineItem :headers="children" />
      </template>
    </li>
  </ul>
</template>

<style scoped>
.root {
  position: relative;
  z-index: 1;
}

.nested {
  padding-right: 16px;
  padding-left: 16px;
}

.outline-link {
  display: block;
  line-height: 32px;
  font-size: 14px;
  font-weight: 400;
  color: var(--vp-c-text-2);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  transition: color 0.5s;
}

.outline-link:hover,
.outline-link.active {
  color: var(--vp-c-text-1);
  transition: color 0.25s;
}

.outline-link.nested {
  padding-left: 13px;
}
</style>
