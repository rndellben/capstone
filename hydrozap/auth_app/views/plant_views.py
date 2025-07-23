from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from firebase_admin import db
from datetime import datetime, timedelta
import logging
from .device_views import notify_device_update
from .alert_views import notify_alert_update
import uuid
from .notification_utils import send_fcm_notification
import io
import csv
import json
logger = logging.getLogger(__name__)

class PlantProfileView(APIView):
    def get(self, request, identifier=None):
        """Retrieve plant profiles based on user_id and identifier"""
        user_id = request.query_params.get('user_id')
        
        if identifier:
            # Get a specific plant profile by identifier
            plant_profiles_ref = db.reference(f'plant_profiles/{identifier}')
            plant_profile = plant_profiles_ref.get()

            if not plant_profile:
                return Response({"error": "Plant profile not found"}, status=status.HTTP_404_NOT_FOUND)

            # Check if user has access to this profile
            profile_user_id = plant_profile.get('user_id')
            if profile_user_id and profile_user_id != user_id:
                return Response({"error": "Access denied"}, status=status.HTTP_403_FORBIDDEN)

            return Response({"plant_profile": plant_profile}, status=status.HTTP_200_OK)
            
            # Get all plant profiles
        plant_profiles_ref = db.reference('plant_profiles')
        plant_profiles = plant_profiles_ref.get()

        if not plant_profiles:
            return Response({"error": "No plant profiles found"}, status=status.HTTP_404_NOT_FOUND)

        # Filter profiles based on user_id
        filtered_profiles = {}
        for profile_id, profile in plant_profiles.items():
            profile_user_id = profile.get('user_id')
            
            # Include profile if:
            # 1. It belongs to the requesting user, OR
            # 2. It's a public profile (no user_id)
            if (profile_user_id == user_id) or (profile_user_id is None):
                filtered_profiles[profile_id] = profile

        return Response({"plant_profiles": filtered_profiles}, status=status.HTTP_200_OK)

    def post(self, request):
        """Add a new plant profile"""
        data = request.data
        identifier = data.get('identifier')
        user_id = data.get('user_id')

        if not identifier:
            return Response({"error": "Identifier is required"}, status=400)
            
        if not user_id:
            return Response({"error": "User ID is required"}, status=400)

        # Check if the profile already exists
        plant_profiles_ref = db.reference(f'plant_profiles/{identifier}')
        if plant_profiles_ref.get():
            return Response({"error": "Plant profile with this identifier already exists"}, status=400)

        # Save plant profile data with user_id
        data['mode'] = data.get('mode', 'simple')  # Add mode field with default "simple"
        plant_profiles_ref.set(data)

        return Response({"message": "Plant profile added successfully"}, status=status.HTTP_201_CREATED)

    def delete(self, request, identifier):
        """Delete a plant profile by identifier"""
        plant_profiles_ref = db.reference(f'plant_profiles/{identifier}')
        if not plant_profiles_ref.get():
            return Response({"error": "Plant profile not found"}, status=status.HTTP_404_NOT_FOUND)

        plant_profiles_ref.delete()
        return Response({"message": "Plant profile deleted successfully"}, status=status.HTTP_200_OK)

    def patch(self, request, identifier):
        """Partially update a plant profile by identifier"""
        plant_profiles_ref = db.reference(f'plant_profiles/{identifier}')
        existing_profile = plant_profiles_ref.get()
        
        if not existing_profile:
            return Response({"error": "Plant profile not found"}, status=status.HTTP_404_NOT_FOUND)

        # Check if user has access to this profile
        user_id = request.query_params.get('user_id')
        profile_user_id = existing_profile.get('user_id')
        if profile_user_id and profile_user_id != user_id:
            return Response({"error": "Access denied"}, status=status.HTTP_403_FORBIDDEN)

        # Prepare update data
        updated_data = {}
        
        # Update fields if provided in request
        for field in ['name', 'description', 'optimal_conditions', 'mode', 'user_id']:
            if field in request.data:
                updated_data[field] = request.data[field]

        # Add timestamp for when profile was updated
        updated_data['updated_at'] = datetime.now().isoformat()

        # Update the profile
        plant_profiles_ref.update(updated_data)

        # Get the updated profile
        updated_profile = plant_profiles_ref.get()

        return Response({
            "message": "Plant profile updated successfully",
            "plant_profile": updated_profile
        }, status=status.HTTP_200_OK)

class PlantProfileCSVUploadView(APIView):
    def post(self, request):
        user_id = request.data.get('user_id')
        csv_file = request.FILES.get('file')

        if not user_id:
            return Response({"error": "User ID is required"}, status=status.HTTP_400_BAD_REQUEST)

        if not csv_file:
            return Response({"error": "CSV file is required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            decoded_file = csv_file.read().decode('utf-8')
            io_string = io.StringIO(decoded_file)
            reader = csv.DictReader(io_string)
        except Exception as e:
            return Response({"error": f"Error reading CSV file: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)

        success_count = 0
        skipped = []

        for row in reader:
            identifier = row.get('identifier')
            if not identifier:
                skipped.append({"row": row, "reason": "Missing identifier"})
                continue

            # Check for existing profile
            plant_ref = db.reference(f'plant_profiles/{identifier}')
            if plant_ref.get():
                skipped.append({"identifier": identifier, "reason": "Already exists"})
                continue

            # Parse and validate optimal_conditions JSON
            optimal_conditions_str = row.get('optimal_conditions')
            try:
                parsed_conditions = json.loads(optimal_conditions_str)

                required_stages = ['transplanting', 'vegetative', 'maturation']
                if not all(stage in parsed_conditions for stage in required_stages):
                    skipped.append({
                        "identifier": identifier,
                        "reason": "Missing one or more growth stages in optimal_conditions"
                    })
                    continue

                row['optimal_conditions'] = parsed_conditions

            except json.JSONDecodeError:
                skipped.append({
                    "identifier": identifier,
                    "reason": "Invalid JSON in optimal_conditions"
                })
                continue

            # Add required fields
            row['user_id'] = user_id
            row['mode'] = row.get('mode', 'simple')
            row['created_at'] = datetime.now().isoformat()

            # Convert grow_duration_days to int if present
            if 'grow_duration_days' in row:
                try:
                    row['grow_duration_days'] = int(row['grow_duration_days'])
                except Exception:
                    row['grow_duration_days'] = 0

            # Save to Firebase
            plant_ref.set(row)
            success_count += 1

        return Response({
            "message": f"{success_count} profiles uploaded successfully",
            "skipped": skipped
        }, status=status.HTTP_201_CREATED)

class PlantProfileCSVDownloadView(APIView):
    def get(self, request, identifier):
        """Download a plant profile as CSV (template format)"""
        plant_profiles_ref = db.reference(f'plant_profiles/{identifier}')
        plant_profile = plant_profiles_ref.get()

        if not plant_profile:
            return Response({"error": "Plant profile not found"}, status=status.HTTP_404_NOT_FOUND)

        # Prepare CSV header and row (match plant_profiles_template.csv)
        header = [
            "identifier",
            "name",
            "description",
            "notes",
            "mode",
            "grow_duration_days",
            "optimal_conditions"
        ]
        # Compose row
        row = [
            plant_profile.get("identifier", identifier),
            plant_profile.get("name", ""),
            plant_profile.get("description", ""),
            plant_profile.get("notes", ""),
            plant_profile.get("mode", "simple"),
            str(plant_profile.get("grow_duration_days", "")),
            json.dumps(plant_profile.get("optimal_conditions", {}), ensure_ascii=False)
        ]

        # Write CSV to memory with correct quoting and line endings
        output = io.StringIO()
        writer = csv.writer(output, quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
        writer.writerow(header)
        writer.writerow(row)
        csv_content = output.getvalue()
        output.close()

        # Return as downloadable file
        response = Response(csv_content, content_type='text/csv')
        response["Content-Disposition"] = f'attachment; filename="plant_profile_{identifier}.csv"'
        return response

class GrowProfileCSVDownloadView(APIView):
    def get(self, request, profile_id):
        """Download a grow profile as CSV (template format)"""
        grow_profiles_ref = db.reference(f'grow_profiles/{profile_id}')
        grow_profile = grow_profiles_ref.get()

        if not grow_profile:
            return Response({"error": "Grow profile not found"}, status=status.HTTP_404_NOT_FOUND)

        # Generate a random identifier with crop name prefix
        crop_name = grow_profile.get("name", "").lower().replace(" ", "_")
        if not crop_name:
            crop_name = "plant"
        random_id = str(uuid.uuid4())[:8]
        random_identifier = f"{crop_name}_{random_id}"

        # Prepare CSV header and row (match plant_profiles_template.csv)
        header = [
            "identifier",
            "name",
            "description",
            "notes",
            "mode",
            "grow_duration_days",
            "optimal_conditions"
        ]
        # Get the original data
        original_name = grow_profile.get("name", "")
        profile_description = f"Downloaded from HydroZap Global Leaderboard. Original profile: {original_name}"
        profile_notes = "This profile was downloaded from the Global Leaderboard and may represent a high-performing grow configuration."
        
        # Compose row with hardcoded notes and description
        row = [
            random_identifier,  # Generate a random identifier instead of using the ID
            original_name,
            profile_description,  # Hardcoded description mentioning Global Leaderboard
            profile_notes,  # Hardcoded notes
            grow_profile.get("mode", "simple"),
            str(grow_profile.get("grow_duration_days", "")),
            json.dumps(grow_profile.get("optimal_conditions", {}), ensure_ascii=False)
        ]

        # Write CSV to memory with correct quoting and line endings
        output = io.StringIO()
        writer = csv.writer(output, quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
        writer.writerow(header)
        writer.writerow(row)
        csv_content = output.getvalue()
        output.close()

        # Return as downloadable file using Django's HttpResponse instead of REST framework's Response
        from django.http import HttpResponse
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename="grow_profile_{profile_id}.csv"'
        response.write(csv_content)
        return response

class GrowProfileView(APIView):
    def get(self, request, *args, **kwargs):
        user_id = request.GET.get('user_id')
        ref = db.reference('grow_profiles')
        grow_profiles = ref.get()

        if not grow_profiles:
            return Response({"grow_profiles": []})

        filtered_profiles = {
            profile_id: profile
            for profile_id, profile in grow_profiles.items()
            if profile.get('user_id') == user_id
        }

        return Response({"grow_profiles": filtered_profiles})

    def post(self, request):
        required_fields = ["user_id", "name", "plant_profile_id"]
        missing_fields = [field for field in required_fields if field not in request.data]

        if missing_fields:
            return Response(
                {"error": f"Missing required fields: {', '.join(missing_fields)}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user_id = request.data["user_id"]
        name = request.data["name"]
        plant_profile_id = request.data["plant_profile_id"]

        grow_profile_data = {
            "user_id": user_id,
                "name": name,
            "plant_profile_id": plant_profile_id,
            "grow_duration_days": request.data.get("grow_duration_days", 60),
            "is_active": request.data.get("is_active", False),
            "mode": request.data.get("mode", "simple"),  # Add mode field with default "simple"
            "optimal_conditions": request.data.get("optimal_conditions", {
                "transplanting": {},
                "vegetative": {},
                "maturation": {}
            }),
                "created_at": datetime.now().isoformat()
            }
            
        profile_ref = db.reference("grow_profiles")
        profile_id = profile_ref.push().key
        profile_ref.child(profile_id).set(grow_profile_data)
            
        return Response({
            "message": "Grow profile created successfully",
            "profile_id": profile_id,
            "grow_profile": grow_profile_data,
        }, status=status.HTTP_201_CREATED)

    def put(self, request, profile_id):
        profile_ref = db.reference(f"grow_profiles/{profile_id}")
        existing_profile = profile_ref.get()

        if not existing_profile:
            return Response({"error": "Grow profile not found"}, status=status.HTTP_404_NOT_FOUND)

        updated_data = {}

        if "name" in request.data:
            updated_data["name"] = request.data["name"]
        if "plant_profile_id" in request.data:
            updated_data["plant_profile_id"] = request.data["plant_profile_id"]
        if "grow_duration_days" in request.data:
            updated_data["grow_duration_days"] = request.data["grow_duration_days"]

        # Handle optimal conditions per stage
        if "optimal_conditions" in request.data:
            new_conditions = request.data["optimal_conditions"]
            existing_conditions = existing_profile.get("optimal_conditions", {})

            for stage in ["transplanting", "vegetative", "maturation"]:
                if stage in new_conditions:
                    if stage not in existing_conditions:
                        existing_conditions[stage] = {}
                    for param in ["temperature_range", "humidity_range", "ec_range", "ph_range", "tds_range"]:
                        if param in new_conditions[stage]:
                            existing_conditions[stage][param] = new_conditions[stage][param]

            updated_data["optimal_conditions"] = existing_conditions

        updated_data["updated_at"] = datetime.now().isoformat()
        profile_ref.update(updated_data)

        updated_profile = profile_ref.get()

        return Response({
            "message": "Grow profile updated successfully",
            "profile_id": profile_id,
            "grow_profile": updated_profile,
        }, status=status.HTTP_200_OK)

    def delete(self, request, profile_id):
        profile_ref = db.reference(f"grow_profiles/{profile_id}")
        existing_profile = profile_ref.get()

        if not existing_profile:
            return Response({"error": "Grow profile not found"}, status=status.HTTP_404_NOT_FOUND)

        if existing_profile.get("is_active", False):
            return Response(
                {"error": "Cannot delete an active grow profile"},
                status=status.HTTP_400_BAD_REQUEST,
            )
                
        profile_ref.delete()
        return Response({"message": "Grow profile deleted successfully"}, status=status.HTTP_200_OK)
    def patch(self, request, profile_id):
        profile_ref = db.reference(f"grow_profiles/{profile_id}")
        existing_profile = profile_ref.get()

        if not existing_profile:
            return Response({"error": "Grow profile not found"}, status=status.HTTP_404_NOT_FOUND)

        updated_data = {}

        # Update basic fields if provided
        for field in ["name", "plant_profile_id", "grow_duration_days", "is_active"]:
            if field in request.data:
                updated_data[field] = request.data[field]

        # Merge optimal_conditions
        if "optimal_conditions" in request.data:
            new_conditions = request.data["optimal_conditions"]
            existing_conditions = existing_profile.get("optimal_conditions", {})

            for stage, stage_data in new_conditions.items():
                if stage not in existing_conditions:
                    existing_conditions[stage] = {}
                for param, value in stage_data.items():
                    existing_conditions[stage][param] = value

            updated_data["optimal_conditions"] = existing_conditions

        updated_data["updated_at"] = datetime.now().isoformat()
        profile_ref.update(updated_data)

        updated_profile = profile_ref.get()

        return Response({
            "message": "Grow profile partially updated successfully",
            "profile_id": profile_id,
            "grow_profile": updated_profile,
        }, status=status.HTTP_200_OK)

class GrowView(APIView):
    def post(self, request):
        """Add a new grow record"""
        data = request.data
        grow_id = data.get('grow_id')

        if not grow_id:
            return Response({"error": "Grow ID is required"}, status=400)

        device_id = data.get("device_id")
        if not device_id:
            return Response({"error": "Device ID is required"}, status=400)

        # Check if device is already assigned to an active grow
        grows_ref = db.reference('grows')
        existing_grows = grows_ref.get() or {}
        
        # Check if the device is already assigned to any active grow
        for existing_grow_id, grow_data in existing_grows.items():
            if grow_data.get('device_id') == device_id and grow_data.get('status') == 'active':
                return Response({
                    "error": "Device is already assigned to an active grow",
                    "device_id": device_id,
                    "grow_id": existing_grow_id
                }, status=status.HTTP_409_CONFLICT)  # 409 Conflict is appropriate here

        # Simplify grow data with necessary fields only
            grow_data = {
            "user_id": data.get("user_id"),
            "grow_name": data.get("grow_name"),
                "device_id": device_id,
            "profile_id": data.get("profile_id"),  # Link to grow profile
            "start_date": data.get("start_date", None),  # Optional if you want
            "status": "active"  # Explicitly set status to active
        }

        # Update device status to in_use
        device_ref = db.reference(f'devices/{device_id}')
        device_data = device_ref.get()
        
        if device_data:
            device_ref.update({
                "status": "in_use",
                "last_updated": datetime.now().isoformat()
            })
            
            # Notify WebSocket clients about device update
            user_id = device_data.get('user_id')
            if user_id:
                notify_device_update(user_id)

        # Save the grow record to Firebase
        grow_ref = db.reference(f'grows/{grow_id}')
        grow_ref.set(grow_data)
            
        return Response({"message": "Grow record added successfully"}, status=status.HTTP_201_CREATED)

    def get(self, request, grow_id=None):
        """Retrieve a single grow record or list all grows"""
        if grow_id:
            # Get a specific grow record
            grow_ref = db.reference(f'grows/{grow_id}')
            grow_data = grow_ref.get()

            if not grow_data:
                return Response({"error": "Grow record not found"}, status=404)
            grow_count = len(grow_data)

            return Response(grow_data, grow_count, status=status.HTTP_200_OK)
        else:
            # Get all grow records
            grows_ref = db.reference('grows')
            grows_data = grows_ref.get()
            
            if not grows_data:
                return Response({"message": "No grow records found"}, status=200)
            
            return Response(grows_data, status=status.HTTP_200_OK)

    def put(self, request, grow_id):
        """Update an existing grow record"""
        if not grow_id:
            return Response({"error": "Grow ID is required for update"}, status=400)

        data = request.data
        grow_ref = db.reference(f'grows/{grow_id}')
        existing_data = grow_ref.get()

        if not existing_data:
            return Response({"error": "Grow record not found"}, status=404)

        # Check if trying to update device_id
        new_device_id = data.get("device_id")
        if new_device_id and new_device_id != existing_data.get("device_id"):
            # Check if device is already assigned to another grow
            grows_ref = db.reference('grows')
            all_grows = grows_ref.get() or {}
            
            for existing_grow_id, grow_data in all_grows.items():
                # Skip the current grow being updated
                if existing_grow_id == grow_id:
                    continue
                    
                if grow_data.get('device_id') == new_device_id:
                    return Response({
                        "error": "Device is already assigned to an active grow",
                        "device_id": new_device_id,
                        "grow_id": existing_grow_id
                    }, status=status.HTTP_409_CONFLICT)

        # Update grow data with relevant fields
        updated_data = {
            "user_id": data.get("user_id", existing_data.get("user_id")),
            "grow_name": data.get("grow_name", existing_data.get("grow_name")),
            "device_id": new_device_id or existing_data.get("device_id"),
            "profile_id": data.get("profile_id", existing_data.get("profile_id")),
            "start_date": data.get("start_date", existing_data.get("start_date")),
            "status": data.get("status", existing_data.get("status", "active")),
            "harvest_date": data.get("harvest_date", existing_data.get("harvest_date")),
        }

        # Check if grow is being marked as harvested
        new_status = data.get("status")
        if new_status == "harvested" and existing_data.get("status") != "harvested":
            # Get device ID from the grow data
            device_id = new_device_id or existing_data.get("device_id")
            if device_id:
                # Update device status to available and clear grow-related data
                device_ref = db.reference(f'devices/{device_id}')
                device_data = device_ref.get()
                
                if device_data:
                    device_ref.update({
                        "status": "available",
                        "active_grow_id": None,  # Clear the active grow ID
                        "thresholds": None,      # Clear the thresholds
                        "last_updated": datetime.now().isoformat()
                    })

        # Update the record in Firebase
        grow_ref.update(updated_data)

        # After updating, notify WebSocket clients
        user_id = data.get('user_id')
        if user_id:
            notify_device_update(user_id)

        return Response({"message": "Grow record updated successfully"}, status=status.HTTP_200_OK)

    def delete(self, request, grow_id):
        """Delete a grow record"""
        if not grow_id:
            return Response({"error": "Grow ID is required for deletion"}, status=400)

        grow_ref = db.reference(f'grows/{grow_id}')
        existing_data = grow_ref.get()

        if not existing_data:
            return Response({"error": "Grow record not found"}, status=404)

        # Check if grow has been harvested
        # We'll look for either a specific status field or check if harvest_date exists
        grow_status = existing_data.get('status', 'active')  # Default to 'active' if not specified
        harvest_date = existing_data.get('harvest_date')
        
        # If grow is still active (not harvested), prevent deletion
        if grow_status == 'active' and not harvest_date:
            return Response({
                "error": "Cannot delete an active grow",
                "message": "This grow is still active. Please harvest it first before deletion.",
                "grow_id": grow_id
            }, status=status.HTTP_409_CONFLICT)

        # Get user_id before deleting the record
        user_id = existing_data.get('user_id')

        # Grow is harvested or has a harvest date, safe to delete
        grow_ref.delete()

        # After deleting, notify WebSocket clients
        if user_id:
            notify_device_update(user_id)

        return Response({"message": "Grow record deleted successfully"}, status=status.HTTP_200_OK)

class HarvestLogView(APIView):
    def post(self, request, device_id, grow_id=None):
        try:
            data = request.data
            
            # Handle both camelCase and snake_case formats
            grow_id = data.get('growId') or data.get('grow_id') or grow_id
            crop_name = data.get('cropName') or data.get('crop_name')
            harvest_date = data.get('harvestDate') or data.get('harvest_date')
            yield_amount = data.get('yieldAmount') or data.get('yield_amount')
            rating = data.get('rating')
            performance_metrics = data.get('performanceMetrics') or data.get('performance_metrics', {})
            remarks = data.get('remarks') or data.get('remarks', '')

            # Check required fields and print what's missing for debugging
            required_fields = {'crop_name': crop_name, 'harvest_date': harvest_date, 
                              'yield_amount': yield_amount, 'rating': rating}
            missing = [k for k, v in required_fields.items() if not v]
            
            if missing:
                return Response({"error": f"Missing required fields: {', '.join(missing)}"}, status=400)

            log_id = str(uuid.uuid4())

            log_data = {
                "device_id": device_id,
                "grow_id": grow_id,
                "crop_name": crop_name,
                "harvest_date": harvest_date,
                "yield_amount": float(yield_amount) if yield_amount else 0,
                "rating": int(rating) if rating else 0,
                "performance_metrics": performance_metrics,
                "remarks": remarks
            }

            db.reference(f"harvest_logs/{log_id}").set(log_data)

            # Mark the grow as harvested if grow_id is provided
            if grow_id:
                grow_ref = db.reference(f'grows/{grow_id}')
                grow_data = grow_ref.get()
                
                if grow_data:
                    # Get the profile ID from the grow data
                    profile_id = grow_data.get('profile_id')
                    
                    # Update the grow with harvested status and harvest date
                    grow_ref.update({
                        "status": "harvested",
                        "harvest_date": harvest_date,
                    })
                    
                    # Update the grow profile status if profile_id exists
                    if profile_id:
                        # Check if any other active grows are using this profile
                        grows_ref = db.reference('grows')
                        all_grows = grows_ref.get() or {}
                        
                        # Count active grows using this profile
                        active_grows_count = sum(
                            1 for g in all_grows.values()
                            if g.get('profile_id') == profile_id 
                            and g.get('status') == 'active'
                            and g.get('grow_id') != grow_id  # Exclude current grow
                        )
                        
                        # Update profile status based on active grows count
                        profile_ref = db.reference(f'grow_profiles/{profile_id}')
                        profile_ref.update({
                            "is_active": active_grows_count > 0
                        })
                    
                    # Update device status to available
                    device_ref = db.reference(f'devices/{device_id}')
                    device_data = device_ref.get()
                    
                    if device_data:
                        # Update device status to available and clear grow-related data
                        device_ref.update({
                            "status": "available",
                            "active_grow_id": None,  # Clear the active grow ID
                            "thresholds": None,      # Clear the thresholds
                            "last_updated": datetime.now().isoformat()
                        })
                        
                        # Notify WebSocket clients about device update
                        user_id = device_data.get('user_id')
                        if user_id:
                            notify_device_update(user_id)

            # Format the response to match the expected client model
            response_data = {
                "logId": log_id,
                "deviceId": device_id,
                "growId": grow_id,
                "cropName": crop_name,
                "harvestDate": harvest_date,
                "yieldAmount": float(yield_amount) if yield_amount else 0,
                "rating": int(rating) if rating else 0,
                "performanceMetrics": performance_metrics,
                "remarks": remarks
            }

            return Response({"message": "Harvest log created", "log_id": log_id, "log": response_data}, status=201)
            
        except Exception as e:
            return Response({"error": str(e)}, status=500)

    def get(self, request, device_id, grow_id=None):
        try:
            ref = db.reference("harvest_logs")
            logs = ref.get()
            
            if not logs:
                return Response({"logs": []}, status=200)

            # Filter logs by device_id and optionally grow_id
            filtered_logs = []
            for log_id, log_data in logs.items():
                if log_data.get("device_id") == device_id:
                    if grow_id is None or log_data.get("grow_id") == grow_id:
                        # Rename fields for client-side compatibility
                        formatted_log = {
                            "logId": log_id,
                            "deviceId": log_data.get("device_id"),
                            "growId": log_data.get("grow_id", ""),
                            "cropName": log_data.get("crop_name", ""),
                            "harvestDate": log_data.get("harvest_date", ""),
                            "yieldAmount": log_data.get("yield_amount", 0),
                            "rating": log_data.get("rating", 0),
                            "performanceMetrics": log_data.get("performance_metrics", {}),
                            "remarks": log_data.get("remarks", "")
                        }
                        filtered_logs.append(formatted_log)

            return Response({"logs": filtered_logs}, status=200)
            
        except Exception as e:
            return Response({"error": str(e)}, status=500)

class HarvestReadinessView(APIView):
    def get(self, request, grow_id):
        """Verify if a grow is ready for harvest"""
        try:
            # Get grow data
            grow_ref = db.reference(f'grows/{grow_id}')
            grow_data = grow_ref.get()
            
            if not grow_data:
                return Response({"error": "Grow not found"}, status=status.HTTP_404_NOT_FOUND)
            
            # Check if already harvested
            if grow_data.get('status') == 'harvested':
                return Response({
                    "ready": False,
                    "message": "This grow has already been harvested",
                    "harvest_date": grow_data.get('harvest_date')
                }, status=status.HTTP_200_OK)
            
            # Get grow profile for duration
            profile_id = grow_data.get('profile_id')
            profile_ref = db.reference(f'grow_profiles/{profile_id}')
            profile_data = profile_ref.get()
            
            if not profile_data:
                return Response({"error": "Grow profile not found"}, status=status.HTTP_404_NOT_FOUND)
            
            # Calculate progress
            start_date = datetime.fromisoformat(grow_data.get('start_date').replace('Z', '+00:00'))
            current_date = datetime.now()
            days_since_start = (current_date - start_date).days
            
            # Get grow duration from profile
            grow_duration = profile_data.get('grow_duration_days', 60)  # Default to 60 days
            
            # Calculate progress percentage
            progress = min(100, (days_since_start / grow_duration) * 100)
            
            # Determine if ready for harvest
            ready_for_harvest = progress >= 100
            
            # If ready for harvest, send notification
            if ready_for_harvest:
                user_id = grow_data.get('user_id')
                grow_name = grow_data.get('grow_name', 'Your grow')
                device_id = grow_data.get('device_id')
                
                # Send FCM notification
                notification_sent = send_fcm_notification(
                    user_id=user_id,
                    title="Harvest Ready! 🌱",
                    body=f"{grow_name} is ready for harvest!",
                    data={
                        'type': 'harvest',
                        'grow_id': grow_id,
                        'device_id': device_id,
                        'alert_type': 'harvest_reminder',
                        'priority': 'high'
                    }
                )
                
                # Log notification status
                if notification_sent:
                    logger.info(f"Harvest ready notification sent to user {user_id} for grow {grow_id}")
                else:
                    logger.warning(f"Failed to send harvest ready notification to user {user_id} for grow {grow_id}")
            
            return Response({
                "ready": ready_for_harvest,
                "progress": progress,
                "days_since_start": days_since_start,
                "total_duration": grow_duration,
                "message": "Grow is ready for harvest" if ready_for_harvest else "Grow is not yet ready for harvest"
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error in harvest readiness check: {str(e)}")
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class GrowCountView(APIView):
    def get(self, request, user_id):  # Accept user_id from path
        """Get the count of grows for a user (only active grows)"""
        try:
            grows_ref = db.reference('grows')
            grows = grows_ref.get()

            if grows:
                filtered_grows = {
                    grow_id: grow_data 
                    for grow_id, grow_data in grows.items()
                    if grow_data.get('user_id') == user_id and grow_data.get('status') == 'active'
                }
                grow_count = len(filtered_grows)
            else:
                grow_count = 0

            return Response({"grow_count": grow_count}, status=status.HTTP_200_OK)
        
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

class ProfileChangeLogView(APIView):
    """
    View for managing grow profile change logs.
    Handles tracking and retrieving history of changes made to grow profiles.
    """
    def get(self, request, profile_id=None):
        """Get change logs for a specific profile or all profiles for a user"""
        user_id = request.query_params.get('user_id')
        
        if not user_id:
            return Response({"error": "User ID is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        if profile_id:
            # Get change logs for a specific profile
            logs_ref = db.reference('profile_change_logs')
            logs = logs_ref.order_by_child('profile_id').equal_to(profile_id).get()
            
            if not logs:
                return Response({"change_logs": []}, status=status.HTTP_200_OK)
            
            # Convert to list and sort by timestamp (newest first)
            logs_list = []
            for log_id, log_data in logs.items():
                # Only include logs for the requesting user
                if log_data.get('user_id') == user_id:
                    log_data['id'] = log_id
                    logs_list.append(log_data)
            
            # Sort by timestamp descending
            logs_list.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
            
            return Response({"change_logs": logs_list}, status=status.HTTP_200_OK)
        else:
            # Get all change logs for the user
            logs_ref = db.reference('profile_change_logs')
            logs = logs_ref.order_by_child('user_id').equal_to(user_id).get()
            
            if not logs:
                return Response({"change_logs": []}, status=status.HTTP_200_OK)
            
            # Convert to list and sort by timestamp (newest first)
            logs_list = []
            for log_id, log_data in logs.items():
                log_data['id'] = log_id
                logs_list.append(log_data)
            
            # Sort by timestamp descending
            logs_list.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
            
            return Response({"change_logs": logs_list}, status=status.HTTP_200_OK)
    
    def post(self, request):
        """Create a new change log entry"""
        data = request.data
        required_fields = ['profile_id', 'user_id', 'user_name', 'changed_fields', 
                           'previous_values', 'new_values', 'change_type']
        
        # Check for required fields
        missing_fields = [field for field in required_fields if field not in data]
        if missing_fields:
            return Response(
                {"error": f"Missing required fields: {', '.join(missing_fields)}"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Generate a unique ID for the change log
        log_id = str(uuid.uuid4())
        
        # Add timestamp
        data['timestamp'] = datetime.now().isoformat()
        
        # Sanitize keys in changed_fields, previous_values, and new_values
        sanitized_data = data.copy()
        
        # Function to sanitize keys in a dictionary
        def sanitize_keys(dictionary):
            if not isinstance(dictionary, dict):
                return dictionary
                
            result = {}
            for key, value in dictionary.items():
                # Replace dots with underscores in keys
                sanitized_key = key.replace('.', '_')
                
                # Recursively sanitize nested dictionaries
                if isinstance(value, dict):
                    result[sanitized_key] = sanitize_keys(value)
                else:
                    result[sanitized_key] = value
            return result
        
        # Sanitize the dictionaries
        sanitized_data['changed_fields'] = sanitize_keys(data['changed_fields'])
        sanitized_data['previous_values'] = sanitize_keys(data['previous_values'])
        sanitized_data['new_values'] = sanitize_keys(data['new_values'])
        
        # Save to Firebase
        log_ref = db.reference(f'profile_change_logs/{log_id}')
        log_ref.set(sanitized_data)
        
        # Return the created log
        response_data = {**sanitized_data, 'id': log_id}
        return Response(response_data, status=status.HTTP_201_CREATED)

class GlobalLeaderboardView(APIView):
    def get(self, request):
        try:
            # Get all harvest logs from Firebase
            ref = db.reference("harvest_logs")
            logs = ref.get()
            
            if not logs:
                return Response({"leaderboard": []}, status=200)

            # Process logs and calculate performance scores
            leaderboard_entries = []
            for log_id, log_data in logs.items():
                # Extract basic information from harvest log
                crop_name_from_log = log_data.get("crop_name", "Unknown")
                yield_amount = log_data.get("yield_amount", 0)
                rating = log_data.get("rating", 0)
                harvest_date = log_data.get("harvest_date", "")
                
                # Get user information (device owner)
                device_id = log_data.get("device_id", "")
                device_ref = db.reference(f"devices/{device_id}")
                device_data = device_ref.get()
                user_id = device_data.get("user_id", "Unknown") if device_data else "Unknown"
                
                # Get grow profile information 
                grow_id = log_data.get("grow_id", "")
                grow_profile_id = ""
                grow_profile_name = "Custom Configuration"
                plant_name = crop_name_from_log  # Default to what's in the log
                growth_duration = 0  # Default growth duration
                optimal_conditions = {}  # Initialize optimal conditions
                
                if grow_id:
                    grow_ref = db.reference(f"grows/{grow_id}")
                    grow_data = grow_ref.get()
                    if grow_data:
                        # Get grow profile information
                        grow_profile_id = grow_data.get("profile_id", "")
                        if grow_profile_id:
                            profile_ref = db.reference(f"grow_profiles/{grow_profile_id}")
                            profile_data = profile_ref.get()
                            if profile_data:
                                grow_profile_name = profile_data.get("name", "Custom Configuration")
                                
                                # Extract optimal growing conditions
                                optimal_conditions = {}
                                
                                # Handle structured optimal conditions format
                                if "optimal_conditions" in profile_data:
                                    # Get the structured optimal conditions
                                    structured_conditions = profile_data.get("optimal_conditions", {})
                                    
                                    # Extract conditions for each growth stage if available
                                    stages = ["transplanting", "vegetative", "maturation"]
                                    stage_conditions = {}
                                    
                                    for stage in stages:
                                        if stage in structured_conditions:
                                            stage_data = structured_conditions[stage]
                                            stage_conditions[stage] = {
                                                "temperature": stage_data.get("temperature_range", {}),
                                                "humidity": stage_data.get("humidity_range", {}),
                                                "ph": stage_data.get("ph_range", {}),
                                                "ec": stage_data.get("ec_range", {})
                                            }
                                    
                                    if stage_conditions:
                                        optimal_conditions["stages"] = stage_conditions
                                
                                # Fall back to flat structure if no structured data or as additional info
                                optimal_conditions.update({
                                    "temperature": profile_data.get("optimal_temperature", {
                                        "min": profile_data.get("min_temperature"),
                                        "max": profile_data.get("max_temperature")
                                    }),
                                    "humidity": profile_data.get("optimal_humidity", {
                                        "min": profile_data.get("min_humidity"),
                                        "max": profile_data.get("max_humidity")
                                    }),
                                    "ph": profile_data.get("optimal_ph", {
                                        "min": profile_data.get("min_ph"),
                                        "max": profile_data.get("max_ph")
                                    }),
                                    "ec": profile_data.get("optimal_ec", {
                                        "min": profile_data.get("min_ec"),
                                        "max": profile_data.get("max_ec")
                                    })
                                })
                                
                                # Get plant profile information to get the actual plant name
                                plant_profile_id = profile_data.get("plant_profile_id", "")
                                if plant_profile_id:
                                    plant_profile_ref = db.reference(f"plant_profiles/{plant_profile_id}")
                                    plant_profile_data = plant_profile_ref.get()
                                    if plant_profile_data:
                                        plant_name = plant_profile_data.get("name", crop_name_from_log)
                                
                                # Get growth duration from profile
                                growth_duration = profile_data.get("grow_duration_days", 0)
                                
                                # If we have start_date in grow_data and harvest_date, calculate actual duration
                                if grow_data.get("start_date") and harvest_date:
                                    try:
                                        start_date = datetime.fromisoformat(grow_data.get("start_date").replace('Z', '+00:00'))
                                        harvest_datetime = datetime.fromisoformat(harvest_date.replace('Z', '+00:00'))
                                        actual_duration = (harvest_datetime - start_date).days
                                        if actual_duration > 0:
                                            growth_duration = actual_duration
                                    except Exception as e:
                                        print(f"Error calculating growth duration: {e}")
                
                # Calculate performance score
                # Base score from rating (0-5 stars)
                base_score = rating * 20  # Convert 0-5 scale to 0-100
                
                # Add bonus from yield amount (normalized)
                # We'll use a simple formula here, but this could be more sophisticated
                yield_bonus = min(yield_amount * 5, 50)  # Cap at 50 points
                
                # Add bonus from performance metrics if available
                metrics_bonus = 0
                performance_metrics = log_data.get("performance_metrics", {})
                if performance_metrics:
                    # Calculate average of normalized metrics (assuming 0-100 scale)
                    metrics_values = [min(value, 100) for value in performance_metrics.values()]
                    if metrics_values:
                        metrics_bonus = sum(metrics_values) / len(metrics_values)
                
                # Total score (weighted)
                total_score = (base_score * 0.4) + (yield_bonus * 0.4) + (metrics_bonus * 0.2)
                
                # Create leaderboard entry
                entry = {
                    "logId": log_id,
                    "userId": user_id,
                    "cropName": plant_name,  # Use the plant name from plant profile
                    "growProfileId": grow_profile_id,
                    "growProfileName": grow_profile_name,  # This is the grow profile name
                    "harvestDate": harvest_date,
                    "yieldAmount": yield_amount,
                    "rating": rating,
                    "performanceMetrics": performance_metrics,
                    "score": round(total_score, 2),
                    "growthDuration": growth_duration,  # Add growth duration to the entry
                    "optimalConditions": optimal_conditions,  # Add optimal growing conditions
                    "remarks": log_data.get("remarks", "")  # Add remarks if present
                }
                
                leaderboard_entries.append(entry)
            
            # Sort by score (highest first)
            leaderboard_entries.sort(key=lambda x: x["score"], reverse=True)
            
            # Add rank to each entry
            for i, entry in enumerate(leaderboard_entries):
                entry["rank"] = i + 1
            
            return Response({"leaderboard": leaderboard_entries}, status=200)
            
        except Exception as e:
            return Response({"error": str(e)}, status=500)