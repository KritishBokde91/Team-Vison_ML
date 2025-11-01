"use client";
import Image from "next/image";
import { Button } from "../ui/button";
import { useRouter } from "next/navigation";

export default function HeroSection() {
  const router = useRouter();
  return (
    <section className="relative min-h-screen w-full flex flex-col items-center justify-center overflow-hidden">
      {/* Parallax Background */}
      <div className="absolute inset-0 -z-10">
        <Image
          src="/hero.png"
          alt="Hero Image"
          priority
          fill
          className="object-cover object-center"
        />
      </div>

      {/* Overlay */}
      <div className="absolute inset-0 bg-black/50 -z-10" />

      {/* Content */}
      <div className="text-center px-4">
        <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6">
          Empowering Civic Engagement
        </h1>
        <p className="text-lg md:text-xl lg:text-2xl text-white mb-8 max-w-2xl mx-auto">
          Join us in making a difference in your community by reporting and
          tracking civic issues with ease.
        </p>
      </div>
      <div className="flex items-center px-4 gap-2">
        <Button
          className="text-md font-bold cursor-pointer px-4 py-3"
          onClick={() => router.push("/signup")}
        >
          Get Started
        </Button>
        <Button
          variant="outline"
          className="text-md cursor-pointer font-bold px-4 py-3"
          onClick={() => router.push("/login")}
        >
          Login
        </Button>
      </div>
    </section>
  );
}
