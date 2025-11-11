# Session Management

## Description
Implement session persistence, token refresh, logout functionality, and handle session expiry gracefully.

## Dependencies
- [ ] 02-authentication/01-supabase-auth-client-setup.md

## Acceptance Criteria
- [ ] Session persists across page refreshes
- [ ] Token auto-refresh working (handled by middleware)
- [ ] Logout functionality implemented
- [ ] Logout clears all client-side state
- [ ] Session expiry handled gracefully (redirect to login)
- [ ] "Session expired" message shown when appropriate
- [ ] Auth state context provider created
- [ ] useAuth hook for accessing current user
- [ ] Protected routes redirect to login if unauthenticated

## Technical Notes
- Session refresh handled by middleware.ts (already exists)
- Create auth context: `src/lib/contexts/AuthContext.tsx`
  ```typescript
  export function AuthProvider({ children }: { children: React.ReactNode }) {
    const [user, setUser] = useState<User | null>(null);
    // Subscribe to auth changes
    useEffect(() => {
      const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
        setUser(session?.user ?? null);
      });
      return () => subscription.unsubscribe();
    }, []);
    return <AuthContext.Provider value={{ user }}>{children}</AuthContext.Provider>;
  }
  ```
- Logout:
  ```typescript
  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push('/login');
  };
  ```
- Protected route HOC: `src/lib/auth/withAuth.tsx`
- Or use middleware for route protection (preferred)
- **GOTCHA**: Clear any user-specific data from React state on logout
- **GOTCHA**: Middleware refreshes session automatically via getUser() call

## Architecture Reference
- src/lib/supabase/middleware.ts (session refresh)
- CLAUDE.md: Authentication patterns
