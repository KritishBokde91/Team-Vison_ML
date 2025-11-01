import Link from "next/link";
import React from "react";
import { MapPin } from "lucide-react";

const navLinks = [
  {
    label: "Home",
    href: "/",
  },
  {
    label: "About",
    href: "/about",
  },
  {
    label: "Contact",
    href: "/contact",
  },
  {
    label: "Login",
    href: "/login",
  },
  {
    label: "Register",
    href: "/register",
  },
];

export default function Navbar() {
  return (
    <header className="absolute top-0 left-0 w-full py-3 z-10 bg-white/70 backdrop-blur-md">
      <div className="w-full max-w-7xl mx-auto flex justify-between items-center ">
        <div className="flex items-center px-4">
          <div className=" text-primary flex size-6 items-center justify-center rounded-md">
            <MapPin className="size-8" />
          </div>
          <h1 className="font-bold text-2xl text-primary ml-2">Civic Sense</h1>
        </div>
        <div className="flex items-center px-4 gap-2">
          {navLinks.map((link) => (
            <Link
              key={link.label}
              href={link.href}
              className="px-4 py-2 text-md  rounded-md"
            >
              {link.label}
            </Link>
          ))}
        </div>
      </div>
    </header>
  );
}
