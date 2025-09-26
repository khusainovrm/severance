<template>
  <div class="cards-section" ref="cardsRef">
    <div class="cards">
      <div v-for="n in 10" :key="n" class="card">Карточка {{ n }}</div>
    </div>

    <!-- бейдж -->
    <div class="badge-wrapper">
      <div class="string" :style="{ height: stringHeight + 'px' }"></div>
      <div ref="badgeRef" class="badge" :style="{ transform: `translateY(${badgeOffset}px)` }">
        <img src="../assets/badge.png" alt="badge" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import gsap from 'gsap';
import ScrollTrigger from 'gsap/ScrollTrigger';

// gsap.registerPlugin(ScrollTrigger);

const cardsRef = ref<HTMLElement | null>(null);
const badgeRef = ref<HTMLElement | null>(null);

const stringHeight = ref(0);
const badgeOffset = ref(-200);

onMounted(() => {
  if (!cardsRef.value || !badgeRef.value) return;

  // Скролл для вытягивания нитки и бейджа
  gsap.to(cardsRef.value, {
    scrollTrigger: {
      markers: true,
      trigger: cardsRef.value,
      start: 'start center',
      end: 'bottom center',
      scrub: true,
      onUpdate: (self) => {
        stringHeight.value = 200 * self.progress;
        badgeOffset.value = -200 + 200 * self.progress;
      },
    },
  });

  // Анимация раскачивания бейджа
  // gsap.to(badgeRef.value, {
  //   rotation: 5, // угол в градусах
  //   transformOrigin: 'top center',
  //   yoyo: true,
  //   repeat: -1,
  //   duration: 2,
  //   ease: 'sine.inOut',
  // });
});
</script>

<style scoped>
.cards-section {
  position: relative;
  min-height: 200vh;
  background: #111;
  color: white;
}

.cards {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 20px;
  padding: 50px;
}

.card {
  background: #333;
  padding: 40px;
  text-align: center;
  border-radius: 8px;
}

.badge-wrapper {
  position: absolute;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  pointer-events: none;
}

.string {
  width: 2px;
  background: white;
  visibility: hidden;
}

.badge {
  width: 160px;
  margin-top: 10px;
}
</style>
