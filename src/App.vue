<template>
  <Scene />
</template>

<script setup lang="ts">
import Scene from './components/Scene.vue';
import { onMounted } from 'vue';
function setVh() {
  const vh = window.innerHeight * 0.01;
  document.documentElement.style.setProperty('--vh', `${vh}px`);
}

onMounted(() => {
  // выставляем при загрузке
  setVh();

  // обновляем при изменении размера или ориентации
  window.addEventListener('resize', setVh);
  window.addEventListener('orientationchange', setVh);
});
</script>

<style scoped></style>
