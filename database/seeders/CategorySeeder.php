<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Category;
use App\Models\User;

class CategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $users = User::all();

        foreach ($users as $user) {
            Category::create([
                'user_id' => $user->id,
                'name' => 'Food & Dining',
                'description' => 'Restaurants, groceries, and food delivery',
                'color' => '#EF4444',
                'is_active' => true,
            ]);

            Category::create([
                'user_id' => $user->id,
                'name' => 'Transportation',
                'description' => 'Gas, public transport, rideshare',
                'color' => '#3B82F6',
                'is_active' => true,
            ]);

            Category::create([
                'user_id' => $user->id,
                'name' => 'Entertainment',
                'description' => 'Movies, games, subscriptions',
                'color' => '#8B5CF6',
                'is_active' => true,
            ]);

            Category::create([
                'user_id' => $user->id,
                'name' => 'Shopping',
                'description' => 'Clothes, electronics, household items',
                'color' => '#F59E0B',
                'is_active' => true,
            ]);

            Category::create([
                'user_id' => $user->id,
                'name' => 'Bills & Utilities',
                'description' => 'Rent, electricity, internet, phone',
                'color' => '#10B981',
                'is_active' => true,
            ]);

            Category::create([
                'user_id' => $user->id,
                'name' => 'Healthcare',
                'description' => 'Medical, dental, pharmacy',
                'color' => '#EC4899',
                'is_active' => true,
            ]);
        }
    }
}
