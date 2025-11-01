"use client";
import FeatureSection from "@/components/landing/feature-section";
import Footer from "@/components/landing/footer";
import HeroSection from "@/components/landing/hero-section";
import Navbar from "@/components/landing/navbar";
import { useAuth } from "@/hook/use-auth";
import { useRouter } from "next/navigation";
import { useEffect } from "react";

export default function LandingPage() {
  const { user, profile, loading } = useAuth();

  const router = useRouter();

  useEffect(() => {
    if (loading) return; // Wait until auth context is hydrated

    if (user && profile?.role === "user") {
      router.push("/dashboard");
    }
  }, [user, profile, loading, router]);

  return (
    <div className="flex flex-col justify-center items-center min-h-screen">
      <Navbar />
      <HeroSection />
      <FeatureSection />
      <Footer />
    </div>
  );
}
