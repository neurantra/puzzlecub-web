import Image from "next/image";

export default function PandaMascot({ hero = false }: { hero?: boolean }) {
  return (
    <span className={`panda-mascot${hero ? " panda-mascot-hero" : ""}`}>
      <Image
        src="/brand/panda-cub.webp"
        alt={
          hero ? "A curious panda cub playing with a colorful puzzle cube" : ""
        }
        width={640}
        height={640}
        sizes={hero ? "(max-width: 700px) 120px, 210px" : "52px"}
        priority={hero}
      />
      {hero && (
        <span className="panda-sparkle" aria-hidden="true">
          ✦
        </span>
      )}
    </span>
  );
}
