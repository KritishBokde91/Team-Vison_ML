"use client";
import FeatureSection from "@/components/landing/feature-section";
import Footer from "@/components/landing/footer";
import HeroSection from "@/components/landing/hero-section";
import Navbar from "@/components/landing/navbar";
import { useAuth } from "@/hook/use-auth";
import { useRouter } from "next/navigation";
import { useEffect } from "react";

export default function DashboardPage() {
  const { user, profile, loading } = useAuth();

  const router = useRouter();

  useEffect(() => {
    if (loading) return; // Wait until auth context is hydrated
    console.log("User:", user);
    console.log("Profile:", profile);

    if (user && profile?.role === "user") {
      router.push("/dashboard/user");
    } else if (user && profile?.role === "officer") {
      router.push("/dashboard/officer");
    } else if (user && profile?.role === "worker") {
      router.push("/dashboard/worker");
    }

    console.log("User:", user);
    console.log("Profile:", profile);
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
