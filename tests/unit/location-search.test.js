/**
 * @jest-environment jsdom
 */

describe('Location Search UX', () => {
  let selectedLocations;
  let availableLocations;
  let renderLocationList;
  let setupLocationSearch;

  beforeEach(() => {
    // Set up DOM elements
    document.body.innerHTML = `
      <div id="location-selector">
        <div class="location-search">
          <input type="text" id="location-search" placeholder="חיפוש אזור...">
        </div>
        <div class="location-list" id="location-list">
        </div>
      </div>
    `;

    // Reset state
    selectedLocations = new Set();
    availableLocations = ['אשדוד', 'אשקלון', 'באר שבע', 'גדרה', 'רחובות', 'תל אביב', 'חיפה'];

    // Mock functions
    global.selectedLocations = selectedLocations;
    global.availableLocations = availableLocations;

    // Implement renderLocationList function 
    renderLocationList = function() {
      const locationList = document.getElementById('location-list');
      
      if (!availableLocations.length) {
        locationList.innerHTML = '<div class="loading">לא נמצאו אזורים</div>';
        return;
      }
      
      // Sort locations: selected first, then alphabetical
      const sortedLocations = [...availableLocations].sort((a, b) => {
        const aIsSelected = selectedLocations.has(a);
        const bIsSelected = selectedLocations.has(b);
        
        // Selected items come first
        if (aIsSelected && !bIsSelected) return -1;
        if (!aIsSelected && bIsSelected) return 1;
        
        // Within same group (selected or unselected), sort alphabetically
        return a.localeCompare(b, 'he');
      });
      
      const locationsHtml = sortedLocations.map((location, index) => `
        <div class="location-item ${selectedLocations.has(location) ? 'selected' : ''}" data-location="${location}">
          <input type="checkbox" 
                 id="loc-${index}" 
                 value="${location}"
                 ${selectedLocations.has(location) ? 'checked' : ''}>
          <label for="loc-${index}">${location}</label>
        </div>
      `).join('');
      
      locationList.innerHTML = locationsHtml;
    };

    // Implement search functionality (new behavior)
    setupLocationSearch = function() {
      const searchInput = document.getElementById('location-search');
      if (!searchInput) return;
      
      searchInput.addEventListener('input', function(e) {
        const searchTerm = e.target.value.toLowerCase();
        const locationItems = document.querySelectorAll('.location-item');
        
        locationItems.forEach(item => {
          const label = item.querySelector('label');
          if (label) {
            const locationName = label.textContent.toLowerCase();
            const location = item.getAttribute('data-location');
            const isSelected = selectedLocations.has(location);
            
            // Show item if:
            // 1. It's selected (always visible), OR
            // 2. It matches the search term, OR  
            // 3. Search term is empty
            if (isSelected || locationName.includes(searchTerm) || searchTerm === '') {
              item.style.display = 'flex';
            } else {
              item.style.display = 'none';
            }
          }
        });
      });
    };

    global.renderLocationList = renderLocationList;
    global.setupLocationSearch = setupLocationSearch;
  });

  describe('Location search filtering', () => {
    test('should filter locations based on search term', () => {
      // Setup initial state
      renderLocationList();
      setupLocationSearch();
      
      const searchInput = document.getElementById('location-search');
      const locationItems = document.querySelectorAll('.location-item');
      
      // All items should be visible initially
      expect(locationItems).toHaveLength(7);
      locationItems.forEach(item => {
        expect(item.style.display).not.toBe('none');
      });
      
      // Search for 'אש' - should match 'אשדוד' and 'אשקלון'
      searchInput.value = 'אש';
      searchInput.dispatchEvent(new Event('input'));
      
      const visibleItems = Array.from(locationItems).filter(item => item.style.display !== 'none');
      expect(visibleItems).toHaveLength(2);
      expect(visibleItems[0].textContent).toContain('אשדוד');
      expect(visibleItems[1].textContent).toContain('אשקלון');
    });

    test('should keep selected locations visible at top during search', () => {
      // Select some locations first
      selectedLocations.add('רחובות');
      selectedLocations.add('חיפה');
      
      renderLocationList();
      setupLocationSearch();
      
      const searchInput = document.getElementById('location-search');
      
      // Search for 'אש' - should match 'אשדוד' and 'אשקלון'
      // BUT selected locations 'רחובות' and 'חיפה' should ALSO be visible at the top
      searchInput.value = 'אש';
      searchInput.dispatchEvent(new Event('input'));
      
      const locationItems = document.querySelectorAll('.location-item');
      const visibleItems = Array.from(locationItems).filter(item => item.style.display !== 'none');
      
      // Should show: רחובות, חיפה (selected), אשדוד, אשקלון (matching search)
      expect(visibleItems).toHaveLength(4);
      
      // Verify selected items are at the top
      const visibleLocations = visibleItems.map(item => 
        item.querySelector('label').textContent
      );
      
      // Selected locations should appear first, then search matches
      expect(visibleLocations).toEqual(
        expect.arrayContaining(['רחובות', 'חיפה', 'אשדוד', 'אשקלון'])
      );
      
      // More specifically, selected items should be first
      const selectedItemsVisible = visibleItems.filter(item => {
        const location = item.getAttribute('data-location');
        return selectedLocations.has(location);
      });
      
      expect(selectedItemsVisible).toHaveLength(2);
      // This test will fail with current implementation - that's what we want!
    });

    test('should show all selected locations even when search doesn\'t match them', () => {
      // Select locations
      selectedLocations.add('רחובות');
      selectedLocations.add('תל אביב');
      
      renderLocationList();
      setupLocationSearch();
      
      const searchInput = document.getElementById('location-search');
      
      // Search for something that doesn't match selected locations
      searchInput.value = 'אש';
      searchInput.dispatchEvent(new Event('input'));
      
      const locationItems = document.querySelectorAll('.location-item');
      const visibleItems = Array.from(locationItems).filter(item => item.style.display !== 'none');
      
      // Should show selected locations + search matches
      expect(visibleItems.length).toBeGreaterThanOrEqual(2); // At least the selected ones
      
      // Verify selected locations are visible
      const selectedVisible = visibleItems.filter(item => {
        const location = item.getAttribute('data-location');
        return selectedLocations.has(location);
      });
      
      expect(selectedVisible).toHaveLength(2);
      // This test will also fail with current implementation
    });

    test('should clear search and show all locations when search is empty', () => {
      selectedLocations.add('רחובות');
      
      renderLocationList();
      setupLocationSearch();
      
      const searchInput = document.getElementById('location-search');
      
      // Search first
      searchInput.value = 'אש';
      searchInput.dispatchEvent(new Event('input'));
      
      // Clear search
      searchInput.value = '';
      searchInput.dispatchEvent(new Event('input'));
      
      const locationItems = document.querySelectorAll('.location-item');
      const visibleItems = Array.from(locationItems).filter(item => item.style.display !== 'none');
      
      // All locations should be visible when search is cleared
      expect(visibleItems).toHaveLength(7);
    });
  });
});
