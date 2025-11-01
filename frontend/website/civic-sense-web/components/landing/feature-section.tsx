import React from "react";

export default function FeatureSection() {
  return (
    <section id="features" className="py-20 bg-gray-50 max-w-7xl">
      <div className="container mx-auto px-6">
        <h2 className="text-3xl font-bold text-center mb-12">
          Why Use CivicFix?
        </h2>
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {/* Feature Card 1 */}
          <div className="bg-white p-6 rounded-lg shadow-md">
            <svg
              className="w-10 h-10 mb-3"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              ></path>
            </svg>
            <h3 className="text-xl font-semibold mb-2">Real-time Tracking</h3>
            <p className="text-gray-600">
              Know exactly what&apos;s happening with your report from
              submission to resolution.
            </p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-md">
            <svg
              className="w-10 h-10 mb-3"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
              ></path>
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
              ></path>
            </svg>
            <h3 className="text-xl font-semibold mb-2">Map-Based View</h3>
            <p className="text-gray-600">
              See all reported issues in your area on an interactive map.
            </p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-md">
            <svg
              className="w-10 h-10 mb-3"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 19.5V11m0 0a2 2 0 00-2-2H3a2 2 0 00-2 2v6a2 2 0 002 2h1.75c.621 0 1.202-.287 1.547-.776L7 11zM14 11V5a2 2 0 00-2-2l-1 4z"
              ></path>
            </svg>
            <h3 className="text-xl font-semibold mb-2">Community Upvoting</h3>
            <p className="text-gray-600">
              Vote on existing reports to show city officials which issues
              matter most.
            </p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-md">
            <svg
              className="w-10 h-10  mb-3"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
              ></path>
            </svg>
            <h3 className="text-xl font-semibold mb-2">Anonymous Reporting</h3>
            <p className="text-gray-600">
              Feel secure by reporting issues without sharing your personal
              information.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
