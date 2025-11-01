"use client";
import { createClient } from "@/utils/supabase/client";
import type { User } from "@supabase/supabase-js";
import { createContext, useContext, useEffect, useState } from "react";

type Profile = {
  id: string;
  name: string | null;
  email: string | null;
  role: string | null;
};

type AuthContextType = {
  user: User | null;
  profile: Profile | null;
  loading: boolean;
};

const AuthContext = createContext<AuthContextType>({
  user: null,
  profile: null,
  loading: true,
});

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState<boolean>(true); // Start as true

  const supabase = createClient();

  useEffect(() => {
    // The loading state is already true from useState,
    // so we just wait for the auth listener to resolve.

    const { data: authListener } = supabase.auth.onAuthStateChange(
      async (_event, session) => {
        const currentUser = session?.user;
        setUser(currentUser ?? null);

        // If user logs in, fetch their profile
        if (currentUser) {
          const { data: profileData, error: profileError } = await supabase
            .from("users")
            .select("*")
            .eq("id", currentUser.id)
            .single();

          if (profileError) {
            console.error("Error fetching profile:", profileError);
            setProfile(null);
          } else {
            setProfile(profileData);
          }
        } else {
          // If user logs out, clear the profile
          setProfile(null);
        }

        // Set loading to false once the user and profile (or lack thereof)
        // have been determined.
        setLoading(false);
      }
    );

    return () => {
      authListener.subscription?.unsubscribe();
    };
  }, [supabase]); // Dependency array is correct// Dependency array is correct

  return (
    <AuthContext.Provider value={{ user, profile, loading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
