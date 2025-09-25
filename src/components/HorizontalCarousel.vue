<template>
  <section class="h-carousel" ref="root">
    <div class="h-carousel__viewport" ref="viewport">
      <ul class="h-carousel__track" ref="track" :style="{ transform: `translateX(${x}px)` }">
        <li
          v-for="(item, i) in items"
          :key="i"
          class="h-carousel__slide"
          :class="{ 'is-active': i === activeIndex }"
          :style="slideStyle(i)"
        >
          <slot name="card" :index="i">Карточка {{ i + 1 }}</slot>
        </li>
      </ul>
    </div>
  </section>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref, watch } from 'vue';
import gsap from 'gsap';

// Props (optional: allow parent to pass items count)
const props = defineProps<{ count?: number }>();

const root = ref<HTMLElement | null>(null);
const viewport = ref<HTMLElement | null>(null);
const track = ref<HTMLElement | null>(null);

const items = ref<number[]>([]);
const activeIndex = ref(0);

// geometry
let slideW = 0; // width of one slide including gap
let gap = 20; // px

// motion state
const x = ref(0); // current translateX
let startX = 0; // pointer start
let dragX = 0; // delta during drag
let isDown = false;
let maxIndex = 0;

let resizeObserver: ResizeObserver | null = null;

function computeSizes() {
  if (!viewport.value) return;
  const vp = viewport.value.getBoundingClientRect();
  const cardWidth = Math.min(360, Math.round(vp.width * 0.7));
  slideW = cardWidth + gap;
  // set CSS variables for layout sizing
  root.value?.style.setProperty('--card-width', cardWidth + 'px');
  root.value?.style.setProperty('--gap', gap + 'px');

  // recenter to current active
  x.value = centerXForIndex(activeIndex.value);
}

function centerXForIndex(i: number) {
  if (!viewport.value) return 0;
  const vp = viewport.value.getBoundingClientRect();
  // Centered so slide i is in the middle of viewport
  const center = (vp.width - slideW) / 2;
  return center - i * slideW;
}

function clampIndex(i: number) {
  return Math.max(0, Math.min(i, maxIndex));
}

function nearestIndexByX(currX: number) {
  // compute the index whose center is closest to currX
  const idx = Math.round(
    (((viewport.value?.getBoundingClientRect().width || 0) - slideW) / 2 - currX) / slideW,
  );
  return clampIndex(idx);
}

function slideStyle(i: number) {
  const vpw = viewport.value?.getBoundingClientRect().width || 1;
  // screen position of slide center
  const slideCenter = x.value + i * slideW + slideW / 2;
  const vpCenter = vpw / 2;
  const offset = slideCenter - vpCenter; // px from center
  const t = offset / slideW; // -1 .. 1 approx near neighbors
  const rot = Math.max(-3, Math.min(3, 3 * Math.sign(t) * Math.min(1, Math.abs(t))));
  return {
    transform: `rotate(${rot.toFixed(3)}deg)`,
  };
}

function updateActiveByX(currX: number) {
  const idx = nearestIndexByX(currX);
  if (idx !== activeIndex.value) {
    activeIndex.value = idx;
  }
}

function snapToNearest(duration = 0.35) {
  const targetIdx = nearestIndexByX(x.value);
  const toX = centerXForIndex(targetIdx);
  gsap.to(x, {
    value: toX,
    duration,
    ease: 'power3.out',
    onUpdate: () => updateActiveByX(x.value),
  });
}

function goToIndex(idx: number, duration = 0.45) {
  idx = clampIndex(idx);
  const toX = centerXForIndex(idx);
  gsap.to(x, {
    value: toX,
    duration,
    ease: 'power3.out',
    onUpdate: () => updateActiveByX(x.value),
    onComplete: () => (activeIndex.value = idx),
  });
}

function onPointerDown(e: PointerEvent) {
  if (!viewport.value) return;
  // Prevent native behaviors (like scrolling/text selection) when starting drag
  e.preventDefault();
  e.stopPropagation();
  isDown = true;
  startX = e.clientX;
  dragX = x.value;
  (e.target as Element).setPointerCapture?.(e.pointerId);
}
function onPointerMove(e: PointerEvent) {
  if (!isDown) return;
  const dx = e.clientX - startX;
  const next = dragX + dx;
  x.value = next;
  updateActiveByX(next);
}
function onPointerUp() {
  if (!isDown) return;
  isDown = false;
  snapToNearest();
}

function onWheel(e: WheelEvent) {
  // Prevent page from scrolling while using carousel wheel/trackpad
  e.preventDefault();
  e.stopPropagation();
  // Horizontal navigation with snap
  const delta = e.deltaY || e.deltaX || 0;
  if (Math.abs(delta) < 2) return;
  const step = delta > 0 ? 1 : -1;
  goToIndex(activeIndex.value + step);
}

onMounted(() => {
  // prepare items
  const count = props.count ?? 8;
  items.value = Array.from({ length: count }, (_, i) => i);
  maxIndex = count - 1;

  // sizes
  computeSizes();
  resizeObserver = new ResizeObserver(computeSizes);
  if (viewport.value) resizeObserver.observe(viewport.value);

  // initial: center first index (0) with others to the right
  activeIndex.value = 0;
  x.value = centerXForIndex(0);

  // listeners
  viewport.value?.addEventListener('pointerdown', onPointerDown);
  window.addEventListener('pointermove', onPointerMove);
  window.addEventListener('pointerup', onPointerUp);
  viewport.value?.addEventListener('wheel', onWheel, { passive: false });
});

onUnmounted(() => {
  resizeObserver?.disconnect();
  viewport.value?.removeEventListener('pointerdown', onPointerDown);
  window.removeEventListener('pointermove', onPointerMove);
  window.removeEventListener('pointerup', onPointerUp);
  viewport.value?.removeEventListener('wheel', onWheel as any);
});

// react on activeIndex change to animate tilts smoothly
watch(activeIndex, () => {
  if (!track.value) return;
  const slides = Array.from(track.value.children) as HTMLElement[];
  slides.forEach((el, i) => {
    const rel = i - activeIndex.value;
    const rot = rel === 0 ? 0 : rel < 0 ? -3 : 3;
    gsap.to(el, { rotate: rot, duration: 0.25, ease: 'power2.out' });
  });
});
</script>

<style scoped>
.h-carousel {
  position: relative;
  width: 100%;
  padding: 40px 0;
  background: transparent;
}
.h-carousel__viewport {
  overflow: hidden;
  width: 100%;
  touch-action: none;
  overscroll-behavior: contain;
  padding: 20px 0;
}
.h-carousel__track {
  display: flex;
  align-items: center;
  gap: var(--gap, 20px);
  will-change: transform;
  user-select: none;
  cursor: grab;
  touch-action: none;
}
.h-carousel__track:active {
  cursor: grabbing;
}

.h-carousel__slide {
  flex: 0 0 var(--card-width, 320px);
  height: 200px;
  border-radius: 16px;
  background: #2b2b2b;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  transform-origin: 50% 100%;
  //box-shadow: 0 10px 24px rgba(0, 0, 0, 0.35);
}
.h-carousel__slide.is-active {
  //box-shadow: 0 16px 40px rgba(0, 0, 0, 0.5);
}
</style>
