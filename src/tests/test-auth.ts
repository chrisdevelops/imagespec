// src/tests/test-auth.ts
import { createClient } from '@supabase/supabase-js'

async function testAuth() {
  await process.loadEnvFile('.env.local');
  console.log('🧪 Starting auth test...\n')
  
  // Check environment variables
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  
  console.log('Environment check:')
  console.log('- Supabase URL:', url || '❌ MISSING')
  console.log('- Anon Key:', key ? '✅ Present' : '❌ MISSING')
  console.log()
  
  if (!url || !key) {
    console.error('❌ Environment variables not loaded!')
    console.log('\nMake sure .env.local exists with:')
    console.log('NEXT_PUBLIC_SUPABASE_URL=http://localhost:54321')
    console.log('NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key')
    return
  }
  
  const supabase = createClient(url, key)

  // Generate unique email for each test
  const testEmail = `test-${Date.now()}@example.com`
  
  console.log(`Creating user with email: ${testEmail}\n`)
  
  // Test signup
  const { data: authData, error: authError } = await supabase.auth.signUp({
    email: testEmail,
    password: 'testpassword123',
  })

  if (authError) {
    console.error('❌ Auth signup error:', authError.message)
    console.error('Full error:', authError)
    return
  }

  if (!authData.user) {
    console.error('❌ No user returned from signup')
    console.log('Auth data:', authData)
    return
  }

  console.log('✅ Auth user created!')
  console.log('   ID:', authData.user.id)
  console.log('   Email:', authData.user.email)
  console.log()

  // Wait a moment for trigger to fire
  console.log('⏳ Waiting for trigger to create public user...')
  await new Promise(resolve => setTimeout(resolve, 1000))

  // Check if public.users was created
  const { data: publicUser, error: publicError } = await supabase
    .from('users')
    .select('*')
    .eq('id', authData.user.id)
    .single()

  if (publicError) {
    console.error('❌ Public user query error:', publicError.message)
    console.error('Full error:', publicError)
    
    // Try to see if any users exist
    const { data: allUsers, error: allError } = await supabase
      .from('users')
      .select('id, email')
    
    console.log('\nAll users in table:', allUsers)
    return
  }

  if (!publicUser) {
    console.error('❌ Public user not found')
    return
  }

  console.log('✅ Public user created!')
  console.log('   ID:', publicUser.id)
  console.log('   Email:', publicUser.email)
  console.log('   Tier:', publicUser.subscription_tier)
  console.log()
  console.log('🎉 Success! Trigger working correctly!')
  console.log('   User exists in both auth.users and public.users')
}

// Run the test
testAuth().catch((error) => {
  console.error('💥 Unhandled error:', error)
  process.exit(1)
})