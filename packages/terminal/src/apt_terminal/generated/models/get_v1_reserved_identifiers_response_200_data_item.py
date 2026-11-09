from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.reserved_identifier_reason import ReservedIdentifierReason
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1ReservedIdentifiersResponse200DataItem")


@_attrs_define
class GetV1ReservedIdentifiersResponse200DataItem:
    """
    Attributes:
        rdid (str):
        entity_type (str):
        entity_id (str):
        reason (ReservedIdentifierReason): What is holding the name. An in-window rename alias and an orphaned mapping
            are deleted outright. A deleted entity is freed the same way when its own table has already let the name go;
            while that table is still holding it, the release renames that row instead and `needsName` is true.
        held_since (None | str): When the name got stuck: an alias's supersede instant, else the row's last write
        releasable (bool): False for names this surface can only report: a revoked token slug (reserved by policy) and
            legacy reverse-domain handles with no parent chain. Releasing a non-releasable row answers 403.
        needs_name (bool): Releasing this one needs a name from you. The deleted row is still sitting on the slug in its
            own table, so freeing it is a rename, and this service does not invent names — send it as `newNames[rdid]` on
            the release.
        object_ (Literal['reserved_identifier'] | Unset):
    """

    rdid: str
    entity_type: str
    entity_id: str
    reason: ReservedIdentifierReason
    held_since: None | str
    releasable: bool
    needs_name: bool
    object_: Literal["reserved_identifier"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        rdid = self.rdid

        entity_type = self.entity_type

        entity_id = self.entity_id

        reason = self.reason.value

        held_since: None | str
        held_since = self.held_since

        releasable = self.releasable

        needs_name = self.needs_name

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "rdid": rdid,
                "entity_type": entity_type,
                "entity_id": entity_id,
                "reason": reason,
                "held_since": held_since,
                "releasable": releasable,
                "needs_name": needs_name,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        rdid = d.pop("rdid")

        entity_type = d.pop("entity_type")

        entity_id = d.pop("entity_id")

        reason = ReservedIdentifierReason(d.pop("reason"))

        def _parse_held_since(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        held_since = _parse_held_since(d.pop("held_since"))

        releasable = d.pop("releasable")

        needs_name = d.pop("needs_name")

        object_ = cast(Literal["reserved_identifier"] | Unset, d.pop("object", UNSET))
        if object_ != "reserved_identifier" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'reserved_identifier', got '{object_}'")

        get_v1_reserved_identifiers_response_200_data_item = cls(
            rdid=rdid,
            entity_type=entity_type,
            entity_id=entity_id,
            reason=reason,
            held_since=held_since,
            releasable=releasable,
            needs_name=needs_name,
            object_=object_,
        )

        get_v1_reserved_identifiers_response_200_data_item.additional_properties = d
        return get_v1_reserved_identifiers_response_200_data_item

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
