"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm, Controller } from "react-hook-form";
import { createClient } from "@/utils/supabase/client";
import { cn } from "@/lib/utils";

import { Button } from "@/components/ui/button";
import {
  Field,
  FieldDescription,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectValue,
} from "@/components/ui/select";
import dynamic from "next/dynamic";

const SafeSelectTrigger = dynamic(
  () => import("@/components/ui/select").then((mod) => mod.SelectTrigger),
  { ssr: false }
);

type FormSchema = {
  name: string;
  email: string;
  role: "user" | "worker" | "officer";
  password: string;
  confirmPassword: string;
};

export function SignupForm({
  className,
  ...props
}: React.ComponentProps<"form">) {
  const router = useRouter();
  const supabase = createClient();

  const {
    register,
    handleSubmit,
    control,
    formState: { errors, isSubmitting },
    setError,
    clearErrors,
  } = useForm<FormSchema>({
    defaultValues: {
      role: "user",
    },
  });

  const [serverError, setServerError] = useState<string | null>(null);

  const onSubmit = async (data: FormSchema) => {
    clearErrors();
    setServerError(null);

    // Front-end validation (extra safety)
    if (data.password.length < 8) {
      setError("password", {
        message: "Password must be at least 8 characters",
      });
      return;
    }
    if (data.password !== data.confirmPassword) {
      setError("confirmPassword", { message: "Passwords do not match" });
      return;
    }

    try {
      const { error } = await supabase.auth.signUp({
        email: data.email,
        password: data.password,
        options: {
          data: {
            full_name: data.name.trim(),
            role: data.role,
          },
        },
      });

      if (error) throw error;

      // Success → go to dashboard (or confirmation page)
      router.push("/dashboard/user");
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Signup failed";
      console.error("Signup error:", err);
      setServerError(message);
    }
  };

  return (
    <form
      className={cn("flex flex-col gap-6", className)}
      {...props}
      onSubmit={handleSubmit(onSubmit)}
    >
      <FieldGroup>
        <div className="flex flex-col items-center gap-1 text-center">
          <h1 className="text-2xl font-bold">Create your account</h1>
          <p className="text-muted-foreground text-sm text-balance">
            Fill in the form below to create your account
          </p>
        </div>

        {/* Full Name */}
        <Field>
          <FieldLabel htmlFor="name">Full Name</FieldLabel>
          <Input
            id="name"
            type="text"
            placeholder="John Doe"
            {...register("name", { required: "Full name is required" })}
            disabled={isSubmitting}
          />
          {errors.name && (
            <FieldDescription className="text-destructive">
              {errors.name.message}
            </FieldDescription>
          )}
        </Field>

        {/* Email */}
        <Field>
          <FieldLabel htmlFor="email">Email</FieldLabel>
          <Input
            id="email"
            type="email"
            placeholder="m@example.com"
            {...register("email", {
              required: "Email is required",
              pattern: {
                value: /^\S+@\S+$/i,
                message: "Invalid email address",
              },
            })}
            disabled={isSubmitting}
          />
          {errors.email && (
            <FieldDescription className="text-destructive">
              {errors.email.message}
            </FieldDescription>
          )}
          <FieldDescription>
            We&apos;ll use this to contact you. We will not share your email
            with anyone else.
          </FieldDescription>
        </Field>

        {/* Role */}
        <Field>
          <FieldLabel>Role</FieldLabel>
          <Controller
            control={control}
            name="role"
            rules={{ required: "Please select a role" }}
            render={({ field }) => (
              <Select
                onValueChange={field.onChange}
                value={field.value}
                disabled={isSubmitting}
              >
                <SafeSelectTrigger>
                  <SelectValue placeholder="Select a role" />
                </SafeSelectTrigger>
                <SelectContent>
                  <SelectItem value="user">User</SelectItem>
                  <SelectItem value="worker">Worker</SelectItem>
                  <SelectItem value="officer">Officer</SelectItem>
                </SelectContent>
              </Select>
            )}
          />
          {errors.role && (
            <FieldDescription className="text-destructive">
              {errors.role.message}
            </FieldDescription>
          )}
          <FieldDescription>
            Choose the role that best describes you.
          </FieldDescription>
        </Field>

        {/* Password */}
        <Field>
          <FieldLabel htmlFor="password">Password</FieldLabel>
          <Input
            id="password"
            type="password"
            {...register("password", {
              required: "Password is required",
              minLength: {
                value: 8,
                message: "Password must be at least 8 characters",
              },
            })}
            disabled={isSubmitting}
          />
          {errors.password && (
            <FieldDescription className="text-destructive">
              {errors.password.message}
            </FieldDescription>
          )}
          <FieldDescription>
            Must be at least 8 characters long.
          </FieldDescription>
        </Field>

        {/* Confirm Password */}
        <Field>
          <FieldLabel htmlFor="confirm-password">Confirm Password</FieldLabel>
          <Input
            id="confirm-password"
            type="password"
            {...register("confirmPassword", {
              required: "Please confirm your password",
            })}
            disabled={isSubmitting}
          />
          {errors.confirmPassword && (
            <FieldDescription className="text-destructive">
              {errors.confirmPassword.message}
            </FieldDescription>
          )}
          <FieldDescription>Please confirm your password.</FieldDescription>
        </Field>

        {/* Server error */}
        {serverError && (
          <FieldDescription className="text-destructive text-center">
            {serverError}
          </FieldDescription>
        )}

        {/* Submit */}
        <Field>
          <Button type="submit" className="w-full" disabled={isSubmitting}>
            {isSubmitting ? "Creating account…" : "Create Account"}
          </Button>
        </Field>

        {/* Login link */}
        <Field>
          <FieldDescription className="px-6 text-center">
            Already have an account?{" "}
            <a href="/login" className="underline underline-offset-4">
              Sign in
            </a>
          </FieldDescription>
        </Field>
      </FieldGroup>
    </form>
  );
}
