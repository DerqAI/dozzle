<template>
  <aside class="fixed flex h-screen w-[inherit] flex-col gap-4 p-3" data-testid="navigation">
    <div v-if="hostname" class="mb-2">
      <small class="block text-sm font-light">{{ hostname }}</small>
    </div>

    <button
      class="input input-sm hover:border-primary mt-2 inline-flex w-auto cursor-pointer items-center gap-2 self-start font-light"
      @click="$emit('search')"
      :title="$t('tooltip.search')"
      data-testid="search"
    >
      <mdi:magnify />
      {{ $t("placeholder.search") }}
      <key-shortcut char="k" class="text-base-content/70"></key-shortcut>
    </button>

    <SideMenu class="flex-1" />
  </aside>
</template>

<script lang="ts" setup>
const { hostname } = config;
</script>

<style scoped></style>
