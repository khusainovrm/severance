<template>
  <div>
    <!-- Секция со сценой -->
    <section ref="sceneSection" class="scene-section">
      <canvas ref="canvas"></canvas>
    </section>

    <!-- Обычный контент после анимации -->
    <section class="content">
      <div class="block">Первый блок</div>
      <div class="block">Второй блок</div>
      <div class="block">Третий блок</div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue';
import * as THREE from 'three';
import gsap from 'gsap';
import ScrollTrigger from 'gsap/ScrollTrigger';
import chair1 from '../assets/char1.png';
import chair2 from '../assets/char2.png';

gsap.registerPlugin(ScrollTrigger);

const canvas = ref<HTMLCanvasElement | null>(null);
const sceneSection = ref<HTMLElement | null>(null);

let camera;
let renderer;

const onResize = () => {
  if (!canvas.value) {
    return;
  }
  const width = window.innerWidth;
  const height = window.innerHeight;
  // Update camera
  camera.aspect = width / height;
  camera.updateProjectionMatrix();

  renderer.setSize(width, height);
};

onMounted(() => {
  if (!canvas.value) {
    return;
  }
  const { width, height } = canvas.value.getBoundingClientRect();

  const scene = new THREE.Scene();
  const axesHelper = new THREE.AxesHelper(5);
  // scene.add(axesHelper);
  scene.background = new THREE.Color(0x000000);

  camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 100);
  camera.position.set(0, 0, 7);

  renderer = new THREE.WebGLRenderer({ canvas: canvas.value, antialias: true });
  renderer.setSize(width, height);

  // === Двери (рамка) ===
  const doorMat = new THREE.MeshBasicMaterial({ color: '#1f1f1f' });

  function createDoorFrame(width: number, height: number) {
    const geom = new THREE.PlaneGeometry(width, height);
    return new THREE.Mesh(geom, doorMat);
  }

  const doorLeft = createDoorFrame(0.97, 2);
  const doorRight = createDoorFrame(0.97, 2);
  doorLeft.position.set(-1.5, 2, 0.01);
  doorRight.position.set(1.5, 2, 0.01);

  const doorsGroup = new THREE.Group();
  doorsGroup.add(doorLeft, doorRight);
  scene.add(doorsGroup);

  // behind the door
  const doorMat2 = new THREE.MeshBasicMaterial({ color: '#d9d9d9' });
  const doorGeom2 = new THREE.PlaneGeometry(2.02, 2.04);
  const behideDoor = new THREE.Mesh(doorGeom2, doorMat2);
  behideDoor.position.set(0, 2, 0);
  doorsGroup.add(behideDoor);

  // === Нить (привязана к лифту) ===
  const lineMat = new THREE.LineBasicMaterial({ color: '#d9d9d9' });
  const lineGeom = new THREE.BufferGeometry().setFromPoints([
    new THREE.Vector3(0, 2, 0),
    new THREE.Vector3(0, -20, 0),
  ]);
  const line = new THREE.Line(lineGeom, lineMat);
  scene.add(line);

  // === Световая дорожка (трапеция, статичная) ===
  const shape = new THREE.Shape();
  shape.lineTo(1.0, 1);
  shape.lineTo(2, -10);
  shape.lineTo(-2, -10);
  shape.lineTo(-1.0, 1);
  shape.lineTo(1.0, 1);

  const lightGeom = new THREE.ShapeGeometry(shape);
  const lightMat = new THREE.MeshBasicMaterial({
    color: '#ffffff',
  });
  const lightOfCone = new THREE.Mesh(lightGeom, lightMat);
  scene.add(lightOfCone);

  // Кресла
  const textureLoader = new THREE.TextureLoader();
  const textureChair1 = textureLoader.load(chair1);
  const textureChair2 = textureLoader.load(chair2);
  textureChair2.wrapS = THREE.RepeatWrapping;
  textureChair2.wrapT = THREE.RepeatWrapping;
  textureChair2.repeat.x = -1;
  const geometry = new THREE.PlaneGeometry(1, 2);
  // const material = new THREE.MeshBasicMaterial({
  //   side: THREE.DoubleSide, wireframe: false, map:
  //   colorTexture,
  // });
  const materialChair1 = new THREE.MeshBasicMaterial({ map: textureChair1, transparent: true });
  const materialChair2 = new THREE.MeshBasicMaterial({ map: textureChair2, transparent: true });
  const char1 = new THREE.Mesh(geometry, materialChair1);
  const char2 = new THREE.Mesh(geometry, materialChair2);
  char1.scale.set(2, 2, 2);
  char2.scale.set(2, 2, 2);

  char1.position.set(-10, -1, 0.2);
  char2.position.set(10, -1, 0.2);
  scene.add(char1, char2);

  // Bottom portal
  const bottomPortal = new THREE.Mesh(
    new THREE.PlaneGeometry(2.5, 2.5),
    new THREE.MeshBasicMaterial({ color: '#ffffff' }),
  );
  bottomPortal.position.set(0, -8, 0);
  const angleDegrees = -90;
  const angleRadians = THREE.MathUtils.degToRad(angleDegrees);
  // Поворот вокруг оси X
  bottomPortal.rotation.x = angleRadians;
  scene.add(bottomPortal);

  // Scroll-driven timeline
  const tl = gsap.timeline({
    scrollTrigger: {
      trigger: sceneSection.value,
      start: 'top top',
      end: '+=4000', // длина виртуального скролла для анимации
      scrub: true,
      pin: true, // фиксируем секцию пока идет анимация
      markers: true,
    },
  });

  // 0. Задержка 2 секунды
  tl.to({}, { delay: 2 }, 0);

  // 1. Закрытие дверей + схлопывание дорожки
  tl.to(doorLeft.position, { x: -0.5, duration: 1 }, '>');
  tl.to(doorRight.position, { x: 0.5, duration: 1 }, '<');
  tl.to(
    lightOfCone.scale,
    { x: 0, duration: 1, onComplete: () => console.log('door closed') },
    "<'",
  );
  tl.to(lightOfCone, { visible: false, duration: 1 }, '<');

  // 2. Лифт едет к центру экрана
  tl.to(
    doorsGroup.position,
    {
      y: -1,
      delay: 2,
      duration: 1,
      onStart: () => {
        console.log('lift move');
      },
    },
    '>',
  );

  // 3. Линия едет вверх
  tl.to(line.position, { y: 20, duration: 6 }, '>');

  // 4. Появление люка в полу
  tl.to(bottomPortal.position, { y: -4, duration: 1 }, '>');

  // 5. Появление стульев
  tl.to(char1.position, { x: -2, duration: 3 }, '>');
  tl.to(char2.position, { x: 2, duration: 3 }, '<');

  // 6. Лифт уезжает под землю
  tl.to(doorsGroup.position, { y: -5.5, duration: 3 }, '>');
  tl.to(line.position, { y: 16, duration: 3 }, '<');

  // === Рендер цикл ===
  function animate() {
    requestAnimationFrame(animate);
    // камера всегда смотрит на лифт, пока он едет
    // camera.position.y = liftGroup.position.y;
    // camera.lookAt(0, liftGroup.position.y, 0);

    char1.visible = char1.position.x >= -5 && char1.position.x <= 5;
    char2.visible = char2.position.x >= -5 && char2.position.x <= 5;

    renderer.render(scene, camera);
  }

  animate();

  window.addEventListener('resize', onResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', onResize);
});
</script>

<style scoped>
.scene-section {
  height: 100vh;
  position: relative;
  overflow: hidden;
}
canvas {
  width: 100%;
  height: 100%;
  display: block;
}
.content {
  min-height: 200vh;
  background: #f0f0f0;
}
.block {
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
}
</style>
